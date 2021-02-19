/**
 * This is a test class for TriggerManagement.
 * 
 * @version 2021-02-14
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-11-15 Created
 * @since 2021-01-29 Added callTriggerTest
 * @since 2021-02-14 DE25830 - Test with actual boolean metadata
 */
@isTest
public class TriggerManagementTest implements Callable {
    static TriggerArguments triggerArgumentsValue = null;

    /**
     * Standard constructor.
     */
    public TriggerManagementTest() {}


    static Integer malformedCount = 0;

    /**
     * Method to invoke all trigger methods on an object.
     */
    public Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'malformed','TEST.FALSE-KEY1','TEST.TRUE-KEY1' {
                malformedCount++;
                throw new ExtensionMalformedCallException('I expected this');
            }
            when 'exception' {
                // we want to throw an exception
                Integer.valueOf(action);
            }
            when else {
                System.assertEquals(TriggerManagementTest.class.getName(),action,'unexpected call action');
                triggerArgumentsValue = new TriggerArguments(args);
                triggerArgumentsValue.callableArguments.put('TestCalled',true);
            }
        }
        return null;
    }

    @isTest
    static void callTriggerTest() {
        BooleanValuesHelper.missingMap = new Map<String,Boolean>();
        System.assertEquals(true,BooleanValuesHelper.getBooleanValue('malformed',true),'BooleanValuesHelper.getBooleanValue(malformed,true)');
        System.assertEquals(true,BooleanValuesHelper.getBooleanValue('TEST.FALSE-KEY1',true),'BooleanValuesHelper.getBooleanValue(TEST.FALSE-KEY1,true)');
        System.assertEquals(false,BooleanValuesHelper.getBooleanValue('TEST.TRUE-KEY1',false),'BooleanValuesHelper.getBooleanValue(TEST.TRUE-KEY1,false)');
        System.assertEquals(true,BooleanValuesHelper.getBooleanValue('exception',true),'BooleanValuesHelper.getBooleanValue(exception,true)');
        System.assertEquals(0,malformedCount,'malformedCount');

        Test.startTest();
        System.assertEquals(true,TriggerManagement.getValueFromMetadata('TEST.TRUE-KEY1',false),'bvHelper check failed');

        try {
            TriggerManagement.callTrigger(new TriggerManagementTest(),'TEST.TRUE-KEY1',new Map<String,Object>());
            System.assert(false,'Expected ExtensionMalformedCallException');
        }
        catch(ExtensionMalformedCallException ex) {
            System.debug('caught expected exception: '+ex);
            System.assertEquals(false,BooleanValuesHelper.getBooleanValue('TEST.TRUE-KEY1',true));
        }
        System.assertEquals(1,malformedCount,'malformedCount');

        // check that an we don't throw if there is no metadata value
        TriggerManagement.callTrigger(new TriggerManagementTest(),'malformed',new Map<String,Object>());
        System.assertEquals(2,malformedCount,'malformedCount');

        // check that an we don't throw if there is the metadata value is false
        TriggerManagement.callTrigger(new TriggerManagementTest(),'TEST.FALSE-KEY1',new Map<String,Object>());
        System.assertEquals(3,malformedCount,'malformedCount');

        // non-malformed exceptions should be thrown
        try {
            TriggerManagement.callTrigger(new TriggerManagementTest(),'exception',new Map<String,Object>());
            System.assert(false,'Expected Exception');
        }
        catch(Exception ex) {
            System.debug('caught expected exception: '+ex);
            System.assertEquals(true,BooleanValuesHelper.getBooleanValue('exception',true));
        }
        Test.stopTest();
        System.assertEquals(3,malformedCount,'malformedCount');
    }

    @isTest
    static void callTest() {
        for(TriggerArguments.TriggerType triggerTypeValue : TriggerManagement.triggerFieldMap.keySet() ) {
            triggerArgumentsValue = null;
            Map<String,Object> args = TriggerArgumentsTest.createArgs( triggerTypeValue );
            args.put(TriggerArguments.TARGET_OBJECT_TYPE_KEY,'DUMMY');
            new TriggerManagement().call(TriggerManagementTest.class.getName(),args.clone());
            System.assertEquals(null,triggerArgumentsValue,'Expected call method not to be invoked');

            args.put(TriggerArguments.TARGET_OBJECT_TYPE_KEY,'TEST');
            new TriggerManagement().call(TriggerManagementTest.class.getName(),args.clone());
            System.assertNotEquals(null,triggerArgumentsValue,'Expected call method to be invoked');
            System.assertEquals('TEST',triggerArgumentsValue.targetObjectType,'Expected target object name to be assigned');
            System.assertEquals(true,(Boolean)triggerArgumentsValue.callableArguments.get('TestCalled'),'Expected call method not to be invoked');
            System.assertEquals(triggerTypeValue,triggerArgumentsValue.triggerTypeValue,'triggerTypeValue');

            try {
                new TriggerManagement().call(null,args.clone());
                System.assert(true,'ExtensionMalformedCallException expected');
            }
            catch(TriggerManagement.ExtensionMalformedCallException ex) {
                System.debug('Expected exception: '+ex);
            }
        }
    }

    @isTest
    static void getUniqueTriggerString() {
        System.assertEquals('AbstractTrigger',TriggerManagement.getUniqueTriggerString('AbstractTrigger'),'AbstractTrigger');
        System.assertEquals(null,TriggerManagement.getUniqueTriggerString(null),'Using null arguments');
    }

    @isTest
    static void getNonEntityValueTest() {
        System.assertEquals('TEST',TriggerManagement.getNonEntityValue('Test'),'getNonEntityValue(\'Test\')');
        System.assertEquals(null,TriggerManagement.getNonEntityValue('Opportunity'),'getNonEntityValue(\'Opportunity\')');
    }

    @isTest
    static void attachmentTest() {
        Account acc = new Account(Name='TestAccount');
        insert acc;
        Attachment attach = new Attachment(Body = Blob.valueOf('anything'),Name='TestAttachment',ParentId=acc.Id);
        // we are only are verifying no exception is thrown
        insert attach;
    }

    public class ExtensionMalformedCallException extends Exception {}
}