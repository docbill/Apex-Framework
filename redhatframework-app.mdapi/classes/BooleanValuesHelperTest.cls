/**
 * Test class for Metadata Values Helper
 * 
 * @version 2020-12-02
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-12-02 - Created
 */
@IsTest
private class BooleanValuesHelperTest {

    static final Map<String,Boolean> missingMap = new Map<String,Boolean>();

    static {
        BooleanValuesHelper.missingMap = missingMap;
    }

    static final String DEFAULT_KEY1 = 'DEFAULT-KEY1';
    static final String DEFAULT_KEY2 = 'DEFAULT-KEY2';
    static final String TEST_DEFAULT_KEY1 = 'TEST.'+DEFAULT_KEY1;
    static final String TEST_DEFAULT_KEY2 = 'TEST.'+DEFAULT_KEY2;
    static final String FALSE_KEY1 = 'FALSE-KEY1';
    static final String FALSE_KEY2 = 'FALSE-KEY2';
    static final String TEST_FALSE_KEY1 = 'TEST.'+FALSE_KEY1;
    static final String TEST_FALSE_KEY2 = 'TEST.'+FALSE_KEY2;
    static final String TRUE_KEY1 = 'TRUE-KEY1';
    static final String TRUE_KEY2 = 'TRUE-KEY2';
    static final String TEST_TRUE_KEY1 = 'TEST.'+TRUE_KEY1;
    static final String TEST_TRUE_KEY2 = 'TEST.'+TRUE_KEY2;

    static BooleanValuesHelper helperGlobal = BooleanValuesHelper.getBooleanValuesHelper('');
    static BooleanValuesHelper helperTest = BooleanValuesHelper.getBooleanValuesHelper('TEST');

    @isTest
    static void booleanMetadataTest() {
        BooleanValuesHelper.useTestingDefaults = false;
        System.assertEquals(null,helperTest.booleanMap.get(DEFAULT_KEY1),'booleanMap.get(DEFAULT_KEY1),booleanMap='+helperTest.booleanMap);
        System.assertEquals(false,helperTest.booleanMap.get(FALSE_KEY1),'booleanMap.get(FALSE_KEY1),booleanMap='+helperTest.booleanMap);
        System.assertEquals(true,helperTest.booleanMap.get(TRUE_KEY1),'booleanMap.get(TRUE_KEY1),booleanMap='+helperTest.booleanMap);
        System.assertEquals(false,helperTest.getValue(DEFAULT_KEY2,false),'getValue(DEFAULT_KEY2,false)');
        System.assertEquals(true,helperTest.getValue(DEFAULT_KEY2,true),'getValue(DEFAULT_KEY2,true)');
        System.assertEquals(false,helperTest.getValue(FALSE_KEY2,true),'getValue(FALSE_KEY2,true)');
        System.assertEquals(true,helperTest.getValue(TRUE_KEY2,false),'getValue(TRUE_KEY2,false)');
        System.assertEquals(false,BooleanValuesHelper.getBooleanValue(TEST_DEFAULT_KEY1,false),'getBooleanValue(TEST_DEFAULT_KEY1,false)');
        System.assertEquals(true,BooleanValuesHelper.getBooleanValue(TEST_DEFAULT_KEY1,true),'getBooleanValue(TEST_DEFAULT_KEY1,true)');
        System.assertEquals(false,BooleanValuesHelper.getBooleanValue(TEST_FALSE_KEY1,true),'getBooleanValue(TEST_FALSE_KEY1,true)');
        System.assertEquals(true,BooleanValuesHelper.getBooleanValue(TEST_TRUE_KEY1,false),'getBooleanValue(TEST_TRUE_KEY1,false)');
        System.assertEquals(false,BooleanValuesHelper.getBooleanValue(TEST_DEFAULT_KEY2,false),'getBooleanValue(TEST_DEFAULT_KEY2,false)');
        System.assertEquals(true,BooleanValuesHelper.getBooleanValue(TEST_DEFAULT_KEY2,true),'getBooleanValue(TEST_DEFAULT_KEY2,true)');
        System.assertEquals(false,BooleanValuesHelper.getBooleanValue(TEST_FALSE_KEY2,true),'getBooleanValue(TEST_FALSE_KEY2,true)');
        System.assertEquals(true,BooleanValuesHelper.getBooleanValue(TEST_TRUE_KEY2,false),'getBooleanValue(TEST_TRUE_KEY2,false)');
        BooleanValuesHelper.useTestingDefaults = true;
        System.assertEquals(null,helperTest.booleanMap.get(DEFAULT_KEY1),'booleanMap.get(DEFAULT_KEY1),booleanMap='+helperTest.booleanMap);
        System.assertEquals(null,helperTest.booleanMap.get(FALSE_KEY1),'booleanMap.get(FALSE_KEY1),booleanMap='+helperTest.booleanMap);
        System.assertEquals(null,helperTest.booleanMap.get(TRUE_KEY1),'booleanMap.get(TRUE_KEY1),booleanMap='+helperTest.booleanMap);
    }

    @isTest
	static void booleanSettingsTest() {
		String key='Testing112312';
        System.assertEquals(true,helperGlobal.getValue(key,true),'Failed get default setting');
        System.assertNotEquals(null,missingMap.get(key),'missingMap='+missingMap);
		System.assertEquals(false,helperGlobal.getValue(key,false),'Failed get default setting');
        System.assertEquals(true,helperTest.getValue(key,true),'Failed get default setting');
		System.assertEquals(false,helperTest.getValue(key,false),'Failed get default setting');
		BooleanSetting__c bs = new BooleanSetting__c(Name=key,Value__c=true);
		insert bs;
		BooleanValuesHelper.booleanSettingMap.clear();
		System.assertEquals(true,helperGlobal.getValue(key,false),'Failed to get Boolean value');
		System.assertEquals(false,helperTest.getValue(key,false),'Failed to get Boolean value');
		BooleanValuesHelper.setValuesWhichStartWith('',false);
		System.assertEquals(false,helperGlobal.getValue(key,false),'Failed to get Boolean value');
		System.assertEquals(false,helperTest.getValue(key,true),'Failed to get Boolean value');
		BooleanValuesHelper.setValuesWhichStartWith('TEST.',true);
		System.assertEquals(false,helperGlobal.getValue(key,false),'Failed to get Boolean value');
		System.assertEquals(true,helperTest.getValue(key,false),'Failed to get Boolean value');
		BooleanValuesHelper.setValuesWhichStartWith(null,null);
		System.assertEquals(true,helperGlobal.getValue(key,false),'Failed to get Boolean value');
		System.assertEquals(false,helperTest.getValue(key,false),'Failed to get Boolean value');
		BooleanValuesHelper.setValuesWhichStartWith('TEST.',true);
		System.assertEquals(true,helperGlobal.getValue(key,false),'Failed to get Boolean value');
		System.assertEquals(true,helperTest.getValue(key,false),'Failed to get Boolean value');
		BooleanValuesHelper.setValuesWhichStartWith('TE',false);
		System.assertEquals(true,helperGlobal.getValue(key,false),'Failed to get Boolean value');
		System.assertEquals(false,helperTest.getValue(key,true),'Failed to get Boolean value');
	}

    @isTest
    static void booleanHierarchyTest() {
        BooleanMetadata__mdt deactivateAll = [
            select DeveloperName, MasterLabel, Value__c 
            from BooleanMetadata__mdt
            where DeveloperName='DeactivateAll'];
        BooleanHierarchy__c bh = BooleanValuesHelper.booleanHierarchyInstance;

        BooleanValuesHelper helper = BooleanValuesHelper.getBooleanValuesHelper('');

        Test.startTest();
        // test we get true as a default when requested in test classes
        Boolean result = helper.getValue(deactivateAll.MasterLabel,true);
        System.assertEquals(true,result);

        BooleanValuesHelper.useTestingDefaults = true;
        // test we get false as a default when requested in test classes
        result = helper.getValue(deactivateAll.MasterLabel,false);
        System.assertEquals(false,result);

        // now test as if this is not a test class
        BooleanValuesHelper.useTestingDefaults = false;
        bh.put(deactivateAll.DeveloperName+'__c',Decimal.valueOf(0));
        result = helper.getValue(deactivateAll.MasterLabel,true);
        System.assertEquals(false,result);

        BooleanValuesHelper.useTestingDefaults = false;
        bh.put(deactivateAll.DeveloperName+'__c',Decimal.valueOf(1));
        result = helper.getValue(deactivateAll.MasterLabel,false);
        System.assertEquals(true,result);

        BooleanValuesHelper.useTestingDefaults = false;
        bh.put(deactivateAll.DeveloperName+'__c',null);
        result = helper.getValue(deactivateAll.MasterLabel,true);
        System.assertEquals(true,result);

        BooleanValuesHelper.useTestingDefaults = false;
        result = helper.getValue('__TESTING__',true);
        System.assertEquals(true,result);

        helper = BooleanValuesHelper.getBooleanValuesHelper('TEST');
        System.assertEquals('__TESTING__',BooleanValuesHelper.getKey('TEST.','TEST.__TESTING__'),'getKey failed');
        result = helper.getValue('__TESTING__',true);
        System.assertEquals(true,result);

        Test.stopTest();
	}

	@isTest
	static void getBooleanValueTest() {
		String key='Testing112312';
		System.assertEquals(true,BooleanValuesHelper.getBooleanValue(key,true),'Failed get default setting');
        System.assertEquals(false,BooleanValuesHelper.getBooleanValue(key,false),'Failed get default setting');
        helperGlobal.booleanMap.put(key,true);
        BooleanValuesHelper.booleanSettingMap.clear();
		System.assertEquals(true,helperGlobal.getValue(key,false),'Failed get default setting'+helperGlobal.booleanMap);
		System.assertEquals(true,BooleanValuesHelper.getBooleanValue(key,false),'Failed get default setting'+helperGlobal.booleanMap);
        helperTest.booleanMap.put(key,false);
        BooleanValuesHelper.booleanSettingMap.clear();
		System.assertEquals(false,BooleanValuesHelper.getBooleanValue('TEST.'+key,true),'Failed get default setting');
	}

    @isTest
	static void createMissingBooleanMetadataTest() {
        Map<String,Boolean> missingMap = (new Map<String,Boolean>{TEST_DEFAULT_KEY1 => true});
		BooleanValuesHelper.missingMap = missingMap;

		Test.startTest();
		Map<String,Metadata.CustomMetadata> metadataMap = BooleanValuesHelper.createMissingBooleanMetadata();
        System.assertEquals(0,metadataMap.size(),'Expected all duplicates: '+metadataMap);
        System.assertNotEquals(null,BooleanValuesHelper.missingMap,'BooleanValuesHelper.missingMap');

		missingMap.put('TEST.TEST-TEST-TEST',false);
		metadataMap = BooleanValuesHelper.createMissingBooleanMetadata();
		System.assertEquals(1,metadataMap.size(),'Expected a key '+metadataMap);
        System.assertEquals(null,BooleanValuesHelper.missingMap,'BooleanValuesHelper.missingMap');

        BooleanValuesHelper.missingMap = missingMap;
		missingMap.put('TEST.TEST_TEST_TEST',false);
		metadataMap = BooleanValuesHelper.createMissingBooleanMetadata();
		System.assertEquals(1,metadataMap.size(),'Expected a key '+metadataMap);
        System.assertEquals(null,BooleanValuesHelper.missingMap,'BooleanValuesHelper.missingMap');
		Test.stopTest();
	}

    // the following are tests to boost coverage
	@isTest
	static void coverageTests() {
		BooleanValuesHelper.DeployCallback callback = new BooleanValuesHelper.DeployCallback();
		Metadata.DeployResult result = new Metadata.DeployResult();
		callback.handleResult(result,null);
		result.status = Metadata.DeployStatus.Succeeded;
		callback.handleResult(result,null);
	}

}