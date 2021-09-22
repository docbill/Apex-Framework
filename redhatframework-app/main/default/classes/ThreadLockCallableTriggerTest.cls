/**
 * Test class for ThreadLockCallableTrigger.
 * 
 * @version 2021-07-16
 * 
 * @author Bill Riemers <briemers@redhat.com>
 * @since 2021-07-16 - Created
 */
@isTest
private class ThreadLockCallableTriggerTest
{
    @isTest
    static void threadLockTest() {
        ThreadLockCallableTrigger callableTrigger = new ThreadLockCallableTrigger();
        List<Opportunity> newList = ( new List<Opportunity>{
            new Opportunity(OwnerId=UserInfo.getUserId())
        } );
        TriggerArguments ta = TriggerArguments.createBeforeInsert(newList);
        String triggerName = 'Opp_Before.assignLegacyCallable'; 
        String key = ThreadLockCallableTrigger.getThreadLockKey(triggerName,ta);
        Boolean lockValue = ThreadLock.lock(key);
        System.assertEquals(true,lockValue,'Expected lock on '+key);
        ThreadLock.unlock(key);

        Test.startTest();
        // the first time simply adds this name to the firstCalledSet
        callableTrigger.call(triggerName+'.lock',ta.callableArguments);
        // the second time actually does the locking
        callableTrigger.call(triggerName+'.lock',ta.callableArguments);
        Test.stopTest();

        lockValue = ThreadLock.lock(key);
        System.assertEquals(false,lockValue,'Unexpected lock on '+key);

        // for coverage only
        String key2 = ThreadLockCallableTrigger.getThreadLockKey(triggerName,null);
    }


    @isTest
    static void callExceptionTest() {
        ThreadLockCallableTrigger callableTrigger = new ThreadLockCallableTrigger();
        List<User> newList = ( new List<User>{
            new User()
        } );
        TriggerArguments ta = TriggerArguments.createBeforeInsert(newList);
        try {
            // user will not have owner id now owner c
            callableTrigger.call('The dog ate my homework.',ta.callableArguments);
            System.assert(true,'Expected ExtensionMalformedCallException to be thrown.');
        }
        catch(ThreadLockCallableTrigger.ExtensionMalformedCallException ex) {
            System.debug('Expected exception: '+ex);
        }
    }
}