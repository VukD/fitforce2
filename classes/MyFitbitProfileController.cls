public with sharing class MyFitbitProfileController {
	
	public String serviceName = 'Fitforce';
	
	public String groupName = 'Fitbit Owners';
	
	public Boolean currentUserAuthed {get;set;}
	
	public String message { get; set; }
	
	public String bodyActivities { get; set; }
	
	public String bodySleep { get; set; }
	
	public Device device {get;set;}
	
	private Fitbit_User__c token;
			
	public Map<String, Object> activitiesMap {get; set;}

	public Map<String, Object> profileMap {get; set;}

	public Map<String, Object> badgesMap {get; set;}

	public Map<String, Object> sleepMap {get; set;}
		
	public List<TimeSeriesEvent> mySleepingList {get; set;}

	public List<TimeSeriesEvent> myCaloriesList {get; set;}

	public List<TimeSeriesEvent> myStepsList {get; set;}

	public List<TimeSeriesEvent> myDistanceList {get; set;}

	public List<ActivitiesComparision> activitesGraph {get; set;}
	
	public String fitbitGroupId {get; set;}
	
	public String calloutDate;

	public String profile {get; set;}

	public String badges {get; set;}
		
	public MyFitbitProfileController() {
		String userId = ApexPages.currentPage().getParameters().get('id');
		if(userId == null) {
			userId = UserInfo.getUserId();
		}
		calloutDate = ApexPages.currentPage().getParameters().get('date');
		if(calloutDate == null) {
			calloutDate = String.valueOf(Date.today());
		}			
		token = Fitbit_User__c.getValues(userId);
		if(token != null) {
			currentUserAuthed = true;
		} else {
			currentUserAuthed = false;
		}
		activitiesMap = new Map<String, Object>();
		mySleepingList = new List<TimeSeriesEvent>();
		myCaloriesList = new List<TimeSeriesEvent>();
		myStepsList = new List<TimeSeriesEvent>();
		myDistanceList = new List<TimeSeriesEvent>();
		if([Select count() From CollaborationGroup where Name =: groupName] > 0)
		{
			fitbitGroupId = [Select Name, Id From CollaborationGroup where Name =: groupName limit 1].Id;	
		}		
	}

    public PageReference loadUserData() {
    	if(!currentUserAuthed) return Page.FitbitSetupPage;
    	executeProfileGET();
    	executeDeviceGET();
    	executeBadgesGET();
    	executeActivitiesGET();
    	executeSleepGET();
    	executeDataOverTimeGET('/sleep/minutesAsleep', mySleepingList);
    	for(TimeSeriesEvent tse : mySleepingList) {
    		tse.eventValue = tse.eventValue/60;
    	}
    	executeDataOverTimeGET('/activities/calories', myCaloriesList);
    	executeDataOverTimeGET('/activities/steps', myStepsList);
    	executeDataOverTimeGET('/activities/distance', myDistanceList);
    	generateActiviteGraph();
    	return null;
    }

    public void generateActiviteGraph() {
    	activitesGraph = new List<ActivitiesComparision>();
    	for(Integer i=0; i<myCaloriesList.size(); i++) {
    		ActivitiesComparision ac = new ActivitiesComparision();
    		ac.eventDate = myCaloriesList.get(i).eventDate;
    		ac.calories = myCaloriesList.get(i).eventValue;
    		ac.steps = myStepsList.get(i).eventValue;
    		activitesGraph.add(ac);
    	}
    }
    
    public PageReference writeToChatterStatus() {
    	User u = new User(Id = UserInfo.getUserId());
    	String status = 'Looks like ' + UserInfo.getName() + ' has just synced with the Fitbit. Check out the results!';
    	u.CurrentStatus = status;
    	update u;
    	
    	if(fitbitGroupId != null) {
			FeedItem post = new FeedItem();
			post.ParentId = fitbitGroupId;
			post.Body = status;
			post.Title = 'Click here to see!!';
			post.LinkUrl = URL.getSalesforceBaseUrl().toExternalForm() + Page.MyFitbitProfilePage.getUrl() + '?id=' + UserInfo.getUserId() + '&date=' + calloutDate;
			insert post; 
    	}
		return null;   	
    }

    public void executeProfileGET() {
    	if(currentUserAuthed) {
    		String url = 'http://api.fitbit.com/1/user/-/profile.json';
	    	String method = 'GET';
	        Http h = new Http();
	        HttpRequest req = new HttpRequest();
	        req.setTimeout(60000);
	        req.setMethod(method);
	        req.setEndpoint(url);
	        FitbitSetupController oa = new FitbitSetupController();
	        oa.sign(req);
	        HttpResponse res = h.send(req);
	        profile = res.getBody();	 
	        profileMap = (Map<String, Object>)JSON.deserializeUntyped(profile);
    	}
    }

    public void executeBadgesGET() {
    	if(currentUserAuthed) {
    		String url = 'http://api.fitbit.com/1/user/-/badges.json';
	    	String method = 'GET';
	        Http h = new Http();
	        HttpRequest req = new HttpRequest();
	        req.setTimeout(60000);
	        req.setMethod(method);
	        req.setEndpoint(url);
	        FitbitSetupController oa = new FitbitSetupController();
	        oa.sign(req);
	        HttpResponse res = h.send(req);
	        badges = res.getBody();	 
	        badgesMap = (Map<String, Object>)JSON.deserializeUntyped(badges);
    	}
    }
	
    public void executeDeviceGET() {
    	if(currentUserAuthed) {
	    	String url = 'https://api.fitbit.com/1/user/-/devices.json';
	    	String method = 'GET';
	        Http h = new Http();
	        HttpRequest req = new HttpRequest();
	        req.setTimeout(60000);
	        req.setMethod(method);
	        req.setEndpoint(url);
	        FitbitSetupController oa = new FitbitSetupController();
	        oa.sign(req);
	        HttpResponse res = h.send(req);
	        device = new Device(JSON.createParser(res.getBody()));	        
    	}
    }
    
    public void executeActivitiesGET() {
    	if(currentUserAuthed) {
	    	String url = 'http://api.fitbit.com/1/user/'+token.Fitbit_User_Id__c+'/activities/date/'+calloutDate+'.json';
	    	String method = 'GET';
	        Http h = new Http();
	        HttpRequest req = new HttpRequest();
	        req.setTimeout(60000);
	        req.setMethod(method);
	        req.setEndpoint(url);
	        FitbitSetupController oa = new FitbitSetupController();
	        oa.sign(req);
	        oa.sign(req);
	        HttpResponse res = h.send(req);
	        bodyActivities = res.getBody();
			activitiesMap = (Map<String, Object>)JSON.deserializeUntyped(bodyActivities);
    	}
    } 
    
    public void executeSleepGET() {
    	if(currentUserAuthed) {
	    	String url = 'http://api.fitbit.com/1/user/'+token.Fitbit_User_Id__c+'/sleep/date/'+calloutDate+'.json';
	    	String method = 'GET';
	        Http h = new Http();
	        HttpRequest req = new HttpRequest();
	        req.setTimeout(60000);
	        req.setMethod(method);
	        req.setEndpoint(url);
	        FitbitSetupController oa = new FitbitSetupController();
	        oa.sign(req);
	        HttpResponse res = h.send(req);
			bodySleep = res.getBody();
	        try {
	        	//sleepToday = (Sleep)JSON.deserializeStrict(res.getBody(),Sleep.class);
	        	sleepMap = (Map<String, Object>)JSON.deserializeUntyped(bodySleep);
    	    } catch(Exception e) {
    	    	ApexPages.addMessages(e);
    		}
    	}
    }

     public void executeDataOverTimeGET(String urlparam, List<TimeSeriesEvent> timeSeriesList) {
    	if(currentUserAuthed) {
	    	String url = 'http://api.fitbit.com/1/user/'+token.Fitbit_User_Id__c+urlparam+'/date/'+calloutDate+'/1w.json';
	    	String method = 'GET';
	        Http h = new Http();
	        HttpRequest req = new HttpRequest();
	        req.setTimeout(60000);
	        req.setMethod(method);
	        req.setEndpoint(url);
	        FitbitSetupController oa = new FitbitSetupController();
	        oa.sign(req);
	        HttpResponse res = h.send(req);
	        JSONParser parser = JSON.createParser(res.getBody());
			while (parser.nextToken() != null) {
	            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) &&  (parser.getText() == 'dateTime')) {
	                TimeSeriesEvent timeEvent = new TimeSeriesEvent();
	                parser.nextToken();	    
	                timeEvent.eventDate = parser.getDateValue().format();
	                parser.nextToken();
	                parser.nextToken();
	                timeEvent.eventValue = Double.valueOf(parser.getText());
	                timeSeriesList.add(timeEvent);
	            }
        	}
    	}
    }
    
    public class TimeSeriesEvent {
    	public String eventDate {get;set;}
    	public Double eventValue {get; set;}
    }

    public class ActivitiesComparision {
    	public String eventDate {get; set;}
    	public Double steps {get; set;}
    	public Double calories {get; set;}
    }        
    
    public class Device {	
    	public String batteryStatus {get; set;}
    	public String deviceVersion {get; set;}
    	public String id {get; set;}
    	public String lastSyncTime {get; set;}
    	public String deviceType {get; set;}
    	
    	public Device(JSONParser parser) {
    		parser.nextToken();
    		parser.nextValue();
    		parser.nextToken();
    		parser.nextValue();    		
    		this.batteryStatus = parser.getText();// Get the value.
    		parser.nextToken();
    		parser.nextValue();
    		this.deviceVersion = parser.getText();// Get the value.     		
    		parser.nextToken();
    		parser.nextValue();
    		this.id = parser.getText();// Get the value. 
    		parser.nextToken();
    		parser.nextValue();
    		this.lastSyncTime = parser.getDatetimeValue().format('MM/dd/yyyy hh:mm:ss a', 'PST');// Get the value.\
    		parser.nextToken();
    		parser.nextValue();    		
    		this.deviceType = parser.getText();// Get the value.
    	}
    }
}