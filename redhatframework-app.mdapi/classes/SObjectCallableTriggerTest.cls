/**
 * This is mainly intended as a sample callable trigger class.
 * 
 * If we have core trigger functionality we want to span across many SObject types,
 * this the the class to implement it in. 
 *
 * @version 2020-11-17
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2020-11-17 - Created
 */
@isTest
private class SObjectCallableTriggerTest
{
    @isTest
    static void assignLegacyTest() {
        SObjectCallableTrigger callableTrigger = new SObjectCallableTrigger();
        List<Opportunity> newList = ( new List<Opportunity>{
            new Opportunity(OwnerId=UserInfo.getUserId())
        } );
        TriggerArguments ta = TriggerArguments.createBeforeInsert(newList);
        callableTrigger.call('Opp_Before.assignLegacyCallable',ta.callableArguments);
        try {
            for(Opportunity opp : newList) {
                System.assertEquals(opp.OwnerId,(Id)opp.get('Owner__c'),'Expected Owner__c assignment from OwnerId');
            }
            System.assertEquals(null,ta.callableArguments.get('exception'),'Exception thrown in callable method.');
        }
        // if the field does not exist, an exception will be thrown
        catch(SObjectException ex) {
            System.assertNotEquals(null,ta.callableArguments.get('exception'),'Expected expection to be thrown in callable method.');
        } 
    }

    @isTest
    static void assignLegacyNegativeTest() {
        SObjectCallableTrigger callableTrigger = new SObjectCallableTrigger();
        List<User> newList = ( new List<User>{
            new User()
        } );
        TriggerArguments ta = TriggerArguments.createBeforeInsert(newList);
        // user will not have owner id now owner c
        callableTrigger.call('User_Before.assignLegacyCallable',ta.callableArguments);
        System.assertNotEquals(null,ta.callableArguments.get('exception'),'Expected expection to be thrown in callable method.');
    }

    @isTest
    static void callExceptionTest() {
        SObjectCallableTrigger callableTrigger = new SObjectCallableTrigger();
        List<User> newList = ( new List<User>{
            new User()
        } );
        TriggerArguments ta = TriggerArguments.createBeforeInsert(newList);
        try {
            // user will not have owner id now owner c
            callableTrigger.call('The dog ate my homework.',ta.callableArguments);
            System.assert(true,'Expected ExtensionMalformedCallException to be thrown.');
        }
        catch(SObjectCallableTrigger.ExtensionMalformedCallException ex) {
            System.debug('Expected exception: '+ex);
        }
    }
}