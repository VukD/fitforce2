@isTest
private class MyFitbitProfileControllerTest {
   
   public static String testDeviceBody = '[{"battery":"High","deviceVersion":"Ultra","id":"521568","lastSyncTime":"2012-08-19T21:30:15.000","type":"TRACKER"}]';
    
   /*public static void createSetup() {
   		OAuthTests.createTestData();
    	Test.setCurrentPage(Page.AuthPage);
    	ApexPages.currentPage().getHeaders().put('Host','testhost');
    	AuthController ac = new AuthController();
    	ac.service = 'test1234';
    	ac.authUrl = 'bogus';
    	ac.message = 'bogus';
    	System.assert(ac.services.size()>0);
    	ac.authorize();
    	Test.setCurrentPage(Page.CompleteAuth);
	    ApexPages.currentPage().getParameters().put('oauth_token','token');
	    ApexPages.currentPage().getParameters().put('oauth_verifier','verifier');
    	ac.completeAuthorization();    	
   }

   @isTest (SeeAllData=false)
   private static void test1() {
    	MyFitbitProfileControllerTest.createSetup();
    	Test.startTest();
    	Test.setCurrentPage(Page.MyFitbitProfilePage);
    	MyFitbitProfileController fitbitController = new MyFitbitProfileController();  
    	fitbitController.loadUserData(); 
    	Test.stopTest();
   }
   
   @isTest (SeeAllData=false)
   private static void test2() {
    	MyFitbitProfileControllerTest.createSetup();
    	Test.startTest();
    	Test.setCurrentPage(Page.MyFitbitProfilePage);
    	MyFitbitProfileController fitbitController = new MyFitbitProfileController();  
    	fitbitController.executeActivitiesGET();
    	Test.stopTest();
   }
   
   @isTest (SeeAllData=false)
   private static void test3() {
    	MyFitbitProfileControllerTest.createSetup();
    	Test.startTest();
    	Test.setCurrentPage(Page.MyFitbitProfilePage);
    	MyFitbitProfileController fitbitController = new MyFitbitProfileController();  
    	fitbitController.executeSleepGET();
    	Test.stopTest();
   } 
   
   @isTest (SeeAllData=false)
   private static void test4() {
    	MyFitbitProfileControllerTest.createSetup();
    	Test.startTest();
    	Test.setCurrentPage(Page.MyFitbitProfilePage);
    	MyFitbitProfileController fitbitController = new MyFitbitProfileController();  
    	fitbitController.executeMinutesAsleepOverTimeGET();    	
    	Test.stopTest();
   }        
      
   @isTest (SeeAllData=false)
   private static void test5() {
   		Test.startTest();
    	Test.setCurrentPage(Page.MyFitbitProfilePage);
    	MyFitbitProfileController fitbitController = new MyFitbitProfileController();  
    	Test.stopTest(); 
   } 

   @isTest (SeeAllData=true)
   private static void test6() {
    	MyFitbitProfileControllerTest.createSetup();
    	Test.startTest();
    	Test.setCurrentPage(Page.MyFitbitProfilePage);
		if([Select count() From CollaborationGroup where Name = 'Fitbit Owners'] == 0)
		{
			CollaborationGroup cg = new CollaborationGroup();
			cg.Name = 'Fitbit Owners';
			insert cg;
		}    	
    	MyFitbitProfileController fitbitController = new MyFitbitProfileController();  
    	fitbitController.writeToChatterStatus();
    	Test.stopTest();
   } 
   
   @isTest (SeeAllData=false)
   private static void test7() {
   	    Test.startTest();
    	MyFitbitProfileController fitbitController = new MyFitbitProfileController(); 
    	MyFitbitProfileController.TimeSeriesEvent tse = new MyFitbitProfileController.TimeSeriesEvent();
    	MyFitbitProfileController.Device dev = new MyFitbitProfileController.Device((JSON.createParser(MyFitbitProfileControllerTest.testDeviceBody)));
    	MyFitbitProfileController.SleepTimes stimes = new MyFitbitProfileController.SleepTimes();
    	MyFitbitProfileController.SleepSummary ssum = new MyFitbitProfileController.SleepSummary();
    	MyFitbitProfileController.Sleep sleep = new MyFitbitProfileController.Sleep();
    	Test.stopTest();
   } 

   public static String createTestData() {
    OAuthService__c s = new OAuthService__c();
    s.name='test1234';
    s.request_token_url__c = 'http://requesttokenurl';
    s.access_token_url__c = 'http://requesttokenurl';
    s.consumer_key__c = 'consumerkey';
    s.consumer_secret__c = 'consumersecret';
    s.authorization_url__c = 'http://testauthorizationurl';
    insert s;
    
    Saved_URL__c u = new Saved_URL__c();
    u.Oauth_Service__c = s.id;
    u.url__c = 'http://testapiurl';
    u.method__c = 'POST';
    u.isform__c = true;
    u.body__c = 'param=test';
    
    insert u;
    return u.id;
  }
  
  public static testMethod void testGetUsersOfService() {
    OAuthTests.createTestData();
    OAuth o = new OAuth();
    o.getUsersOfService('test1234');
  }

    public static testMethod void testAuthorize() {
      
      try {
        OAuthTests.createTestData();
        //Test.setCurrentPage(Page.AuthPage);
        ApexPages.currentPage().getHeaders().put('Host','testhost');
        AuthController ac = new AuthController();
        ac.service = 'test1234';
        ac.authUrl = 'bogus';
        ac.message = 'bogus';
        System.assert(ac.services.size()>0);
        ac.authorize();
        //Test.setCurrentPage(Page.CompleteAuth);
          ApexPages.currentPage().getParameters().put('oauth_token','token');
          ApexPages.currentPage().getParameters().put('oauth_verifier','verifier');
        ac.completeAuthorization();

      }
      catch(Exception e) {
      throw e;
      }
    }
    
    public static testMethod void testTestController() {
      
      try {
        String savedURLID = OAuthTests.createTestData();
        //Test.setCurrentPage(Page.ApiTestPage);
        TestController tc = new TestController();
        
        System.assert(tc.methodList.size()>1);
        
        tc.selectedService = 'test1234';
        
        System.assert(tc.savedURLs.size()==1);
        System.assert(tc.services.size()>0);
        
        tc.url = 'http://testurl';
        tc.method='GET';
        tc.postParam = '';
        tc.body = '';
        tc.selectedService = 'test1234';
        tc.saveURL();
        
        tc.selectedSavedURL = savedURLID;
        
        tc.loadURL();
        
        tc.execute();

      }
      catch(Exception e) {
      throw e;
      }
    }*/       

}