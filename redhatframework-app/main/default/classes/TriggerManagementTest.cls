/**
 * This is a test class for TriggerManagement.
 * 
 * @version 2020-01-29
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-11-15 Created
 * @since 2021-01-29 Added callTriggerTest
 */
@isTest
public class TriggerManagementTest implements Callable {
    static TriggerArguments triggerArgumentsValue = null;

    /**
     * Standard constructor.
     */
    public TriggerManagementTest() {}


    /**
     * Method to invoke all trigger methods on an object.
     */
    public Object call(String action, Map<String, Object> args) {
        switch on action {
            when 'malformed','malformed2' {
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
        BooleanValuesHelper.getBooleanValue('malformed',true);
        System.assertEquals(false,TriggerManagement.bvHelperFromMetadata.getValue('malformed',false),'bvHelper check failed');
        // pretend like we have metadata
        TriggerManagement.bvHelperFromMetadata.booleanMap.put('malformed',true);
        try {
            TriggerManagement.callTrigger(new TriggerManagementTest(),'malformed',new Map<String,Object>());
            System.assert(false,'Expected ExtensionMalformedCallException');
        }
        catch(ExtensionMalformedCallException ex) {
            System.debug('caught expected exception: '+ex);
            System.assertEquals(false,BooleanValuesHelper.getBooleanValue('malformed',true));
        }

        // check that an we don't throw if there is no metadata value
        BooleanValuesHelper.getBooleanValue('malformed2',true);
        TriggerManagement.callTrigger(new TriggerManagementTest(),'malformed2',new Map<String,Object>());

        // non-malformed exceptions should be thrown
        BooleanValuesHelper.getBooleanValue('exception',true);
        try {
            TriggerManagement.callTrigger(new TriggerManagementTest(),'exception',new Map<String,Object>());
            System.assert(false,'Expected Exception');
        }
        catch(Exception ex) {
            System.debug('caught expected exception: '+ex);
            System.assertEquals(true,BooleanValuesHelper.getBooleanValue('exception',true));
        }
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