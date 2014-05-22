public with sharing class FitbitSetupController {
	public Fitbit_Settings__c oAuthSetup {get; set;}

	public Boolean showAuthButton {get; private set;}
	public Boolean consumerKeyRequiredError {get; private set;}
	public Boolean consumerSecretRequiredError {get; private set;}
	public Boolean requestTokenRequiredError {get; private set;}
	public Boolean accessTokenRequiredError {get; private set;}
	public Boolean authURLRequiredError {get; private set;}

	public FitbitSetupController() {
		showAuthButton = true;
		oAuthSetup = Fitbit_Settings__c.getValues('Fitbit');
		if(oAuthSetup == null) {
			oAuthSetup = new Fitbit_Settings__c();
			showAuthButton = false;
		} 
	}

	public PageReference saveSetupData() {
		oAuthSetup.Name = 'Fitbit';
		consumerKeyRequiredError = (oAuthSetup.Consumer_Key__c.isWhitespace()) ? true : false;
		consumerSecretRequiredError = (oAuthSetup.Consumer_Secret__c.isWhitespace()) ? true : false;
		requestTokenRequiredError = (oAuthSetup.Request_Token_URL__c.isWhitespace()) ? true : false;
		accessTokenRequiredError = (oAuthSetup.Access_Token_URL__c.isWhitespace()) ? true : false;
		authURLRequiredError = (oAuthSetup.Authorization_URL__c.isWhitespace()) ? true : false;
		if(consumerKeyRequiredError || consumerSecretRequiredError || requestTokenRequiredError || accessTokenRequiredError ||
			authURLRequiredError) {
			showAuthButton = false;
		} else {
			insert oAuthSetup;
			oAuthSetup = Fitbit_Settings__c.getValues('Fitbit');
			showAuthButton = true;
		}
		return null;
	}

	public PageReference authorize() {
		return new PageReference(newAuthorization());
	}

	private String token;
	private String tokenSecret;
	private Boolean isAccess = false;
	private String verifier;

	private String nonce;
	private String timestamp;
	private String signature;
	private String consumerKey;
	private String consumerSecret;

	private Map<String,String> parameters = new Map<String,String>();
	
	public String message { get; set; }

	public String callbackUrl {get; set; }
	
	public void setConsumerKey(String value) { consumerKey = value; }
	public void setConsumerSecret(String value) { consumerSecret = value; }

	/**
	 * Looks up service name and starts a new authorization process
	 * returns the authorization URL that the user should be redirected to
	 * If null is returned, the request failed. The message property will contain
	 * the reason.
	 */	
	public String newAuthorization() {

		if(callbackUrl==null) {	
			if(ApexPages.currentPage()==null || ApexPages.currentPage().getHeaders().get('Host')==null) {
				message = 'No callback page was set and it couldn\'t be generated from Apex context';
				System.debug(message);
				return null;
			}
	
			callbackUrl = EncodingUtil.urlEncode('https://'+ApexPages.currentPage().getHeaders().get('Host')+
												 Page.FitbitSetupPage.getUrl(),'UTF-8');
		}
				
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setEndpoint(oAuthSetup.request_token_url__c);
		System.debug('Request body set to: '+req.getBody());
		consumerKey = oAuthSetup.consumer_key__c;
		consumerSecret = oAuthSetup.consumer_secret__c;
		sign(req);
		HttpResponse res = null;
		res = h.send(req);
		System.debug('Response from request token request: ('+res.getStatusCode()+')'+res.getBody());
		if(res.getStatusCode()>299) {
			message = 'Failed getting a request token. HTTP Code = '+res.getStatusCode()+
					  '. Message: '+res.getStatus()+'. Response Body: '+res.getBody();
			return null;
		}
		String resParams = res.getBody();
		Map<String,String> rp = getUrlParams(resParams);
		Fitbit_User__c t = new Fitbit_User__c();
		t.Name = UserInfo.getUserId();
		t.token__c = rp.get('oauth_token');
		t.secret__c = rp.get('oauth_token_secret');
		t.isAccess__c = false;

		insert t;
		
		System.debug('Got request token: '+t.token__c+'('+rp.get('oauth_token')+')');
		
		if(oAuthSetup.authorization_url__c.contains('?')) {
			return oAuthSetup.authorization_url__c+'&oauth_token='+EncodingUtil.urlDecode(t.token__c,'UTF-8')+'&oauth_consumer_key='+oAuthSetup.consumer_key__c;
		} else {
			return oAuthSetup.authorization_url__c+'?oauth_token='+EncodingUtil.urlDecode(t.token__c,'UTF-8')+'&oauth_consumer_key='+oAuthSetup.consumer_key__c;
		}
	}
	
	public boolean completeAuthorization(String token, String verifier) {
		System.debug('Completing authorization for request token '+token+' with verifier '+verifier);
		Fitbit_User__c t = null;
		try {
			t =
			[SELECT token__c, secret__c, isAccess__c FROM Fitbit_User__c 
			 WHERE Name=:UserInfo.getUserId() AND token__c = :EncodingUtil.urlEncode(token,'UTF-8') AND isAccess__c = false];
		} catch(System.QueryException e) {
			message = 'Unknown request token: '+token+'. Restart authorization process';
			System.debug(message);
			return false;
			
		}

		oAuthSetup = Fitbit_Settings__c.getValues('Fitbit');
		
		consumerKey = oAuthSetup.Consumer_Key__c;
		consumerSecret = oAuthSetup.Consumer_Secret__c;
		this.token = t.token__c;
		tokenSecret = t.secret__c;
		if(verifier!=null) {
			this.verifier = EncodingUtil.urlEncode(verifier,'UTF-8');
		}
		
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setMethod('POST');
		req.setEndpoint(oAuthSetup.access_token_url__c);
		req.setBody('');
		sign(req);
		HttpResponse res = null;
		res = h.send(req);
		if(res.getStatusCode()>299) {
			message = 'Failed getting an access token. HTTP Code = '+res.getStatusCode()+'. Message: '+res.getStatus()+'. Response Body: '+res.getBody();
			return false;
		}

		String resParams = res.getBody();

		Map<String,String> rp = new Map<String,String>();
		for(String s : resParams.split('&')) {
			List<String> kv = s.split('=');
			rp.put(kv[0],kv[1]);
			System.debug('Access token response param: '+kv[0]+'='+kv[1]);
		}
		
		t.token__c = rp.get('oauth_token');
		t.secret__c = rp.get('oauth_token_secret');
		t.isAccess__c = true;
		t.Fitbit_User_Id__c = rp.get('encoded_user_id');
		update t;
		
		return true;
	}
		
	private void refreshParameters() {
		parameters.clear();
		parameters.put('oauth_consumer_key',consumerKey);
		if(token!=null) {
			parameters.put('oauth_token',token);
		}
		if(verifier!=null) {
			parameters.put('oauth_verifier',verifier);
		}
		parameters.put('oauth_signature_method','HMAC-SHA1');
		parameters.put('oauth_timestamp',timestamp);
		parameters.put('oauth_nonce',nonce);
		parameters.put('oauth_callback',callbackUrl);
	}

	private Map<String,String> getUrlParams(String value) {

		Map<String,String> res = new Map<String,String>();
		if(value==null || value=='') {
			return res;
		}
		for(String s : value.split('&')) {
			System.debug('getUrlParams: '+s);
			List<String> kv = s.split('=');
			if(kv.size()>1) {
				System.debug('getUrlParams:  -> '+kv[0]+','+kv[1]);
				res.put(kv[0],kv[1]);
			}
		}
		return res;
	}

	private String createBaseString(Map<String,String> oauthParams, HttpRequest req) {
		Map<String,String> p = oauthParams.clone();
		if(req.getMethod().equalsIgnoreCase('post') && req.getBody()!=null && 
		   req.getHeader('Content-Type')=='application/x-www-form-urlencoded') {
		   	p.putAll(getUrlParams(req.getBody()));
		}
		String host = req.getEndpoint();
		Integer n = host.indexOf('?');
		if(n>-1) {
			p.putAll(getUrlParams(host.substring(n+1)));
			host = host.substring(0,n);
		}
		List<String> keys = new List<String>();
		keys.addAll(p.keySet());
		keys.sort();
		String s = keys.get(0)+'='+p.get(keys.get(0));
		for(Integer i=1;i<keys.size();i++) {
			s = s + '&' + keys.get(i)+'='+p.get(keys.get(i));
		}

		// According to OAuth spec, host string should be lowercased, but Google and LinkedIn
		// both expect that case is preserved.
		return req.getMethod().toUpperCase()+ '&' + 
			EncodingUtil.urlEncode(host, 'UTF-8') + '&' +
			EncodingUtil.urlEncode(s, 'UTF-8');
	}
	
	public void sign(HttpRequest req) {
		
		Fitbit_User__c t = Fitbit_User__c.getValues(UserInfo.getUserId());
		oAuthSetup = Fitbit_Settings__c.getValues('Fitbit');
				
		consumerKey = oAuthSetup.Consumer_Key__c;
		consumerSecret = oAuthSetup.Consumer_Secret__c;
		if(t != null) {
			this.token = t.token__c;
			tokenSecret = t.secret__c;
		} 
		nonce = String.valueOf(Crypto.getRandomLong());
		timestamp = String.valueOf(DateTime.now().getTime()/1000);

		refreshParameters();
		
		String s = createBaseString(parameters, req);
		
		System.debug('Signature base string: '+s);
		
		Blob sig = Crypto.generateMac('HmacSHA1', Blob.valueOf(s), 
				       Blob.valueOf(consumerSecret+'&'+
				       	            (tokenSecret!=null ? tokenSecret : '')));
		signature = EncodingUtil.urlEncode(EncodingUtil.base64encode(sig), 'UTF-8');
		System.debug('Signature: '+signature);
		
		String header = 'OAuth ';
		for (String key : parameters.keySet()) {
			header = header + key + '="'+parameters.get(key)+'", ';
		}
		header = header + 'oauth_signature="'+signature+'"';
		System.debug('Authorization: '+header);
		req.setHeader('Authorization',header);
	}

    public PageReference completeAuthorizationPage() {
        String token = ApexPages.currentPage().getParameters().get('oauth_token');
        if(token!=null)
        {
            String verifier = ApexPages.currentPage().getParameters().get('oauth_verifier');
            Boolean authSuccess = completeAuthorization(token,verifier);
            if(authSuccess) {
            	return Page.MyFitbitProfilePage;
            }
        }
        return null;
    }
}