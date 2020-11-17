/**
 * This is a test for the abstract trigger class.
 * 
 * @version 2018-01-11
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2018-01-11 depreciated validateSettings
 */
@isTest
public class AbstractTriggerTest extends AbstractTrigger {
	AbstractTriggerTest(Map<Id,SObject> xoldMap,List<SObject> xnewList,Map<Id,SObject> xnewMap) {
		super(xoldMap,xnewList,xnewMap);
	}

	// This method required SeeAllData to work.  As such it should not be used, just call the processTriggerComplete method directly
	// @depreciated
	public static void validateSettings(String prefix) {
//depreciated		String message = 'Missing BooleanSettings__c values:';
//depreciated		String errorMessage = message;
//depreciated		for(String key : AbstractTrigger.missingSettingMap.keySet()) {
//depreciated			if(key.startsWith(prefix) && BooleanSetting__c.getInstance(key) == null) {
//depreciated				errorMessage += ' '+key;
//depreciated			}
//depreciated		}
//depreciated		System.assertEquals(message,errorMessage);
		AbstractTrigger.processTriggerComplete();
	}

	public static void assignLegacyTest(AbstractTrigger beforeTrigger) {
		beforeTrigger.assignLegacy();
		for(SObject obj : beforeTrigger.newSObjectList) {
			System.assertEquals((Id)obj.get('OwnerId'),(Id)obj.get('Owner__c'));
		}
	}

	public static void deployTest(String prefix, List<SObject> objects) {
		deployTest(prefix,objects,false,false,false);
	}

	public static void deployTest(String prefix, List<SObject> objects,Boolean insertAll,Boolean skipUpdate,Boolean skipDelete) {
//	We now use an overrideSettingMap to elliminate the need for all this work
//		Boolean isEmpty = BooleanSetting__c.getAll().isEmpty();
//		// Turn on all the triggers, and make sure everything is tested.
//		if(isEmpty) {
//			// this is to allow us to determine the setting names
//			// when all data is not visible
//			AbstractTrigger.insertMissing = 0;
//			System.debug('Inserting once to learn the setting names');
//			Savepoint sp = Database.setSavepoint();
//			SObject o = objects[0];
//			if(o.Id == null) {
//				Database.insert(o.clone(),false);
//			}
//			else {
//				Database.update(o.clone(true),false);
//			}
//			Database.rollback(sp);
//			for(String key : AbstractTrigger.booleanSettingMap.keySet()) {
//				if(key.startsWith(prefix)) {
//					AbstractTrigger.booleanSettingMap.put(key,true);
//				}
//			}
//		}
//		else {
			AbstractTrigger.setBooleanSettings(prefix,true);
//		}
		System.debug('All settings starting with '+prefix+' have been activated');
		Database.SaveResult failure = null;
		if(objects[0].Id == null) {
			if(insertAll || objects.size() < 2) {
				insert objects;
			}
			else {
				// sometimes we expect failures due to record type selection or such
				for(Database.SaveResult sr : Database.insert(objects,false) ) {
					SObject o = objects.remove(0);
					if(sr.isSuccess()) {
						objects.add(o);
					}
					else {
						System.debug('Insert failure: '+sr.getErrors());
						failure = sr;
					}
				}
				System.assert(! objects.isEmpty(),'No objects could be inserted:\n'+failure);
			}
		}
		if(!skipUpdate) {
			update objects;
		}
		if(!skipDelete) {
			delete objects;
		}
//	We now use an overrideSettingMap to elliminate the need for all this work
//		if(! isEmpty) {
//			// our test is invalid if some of the triggers were not activated
//			validateSettings(prefix);
//		}
	}

	@isTest
	static void booleanSettingsTest() {
		String key='Testing112312';
		System.assert(AbstractTrigger.isActive(key,true),'Failed get default setting');
		System.assert(! AbstractTrigger.isActive(key,false),'Failed get default setting');
		BooleanSetting__c bs = new BooleanSetting__c(Name=key,Value__c=true);
		insert bs;
		AbstractTrigger.booleanSettingMap.clear();
		System.assert(AbstractTrigger.isActive(key,false),'Failed to get Boolean value');
		AbstractTrigger.booleanSettingMap.clear();
		AbstractTrigger.setBooleanSettings('',false);
		System.assert(! AbstractTrigger.isActive(key,true),'Failed to set boolean setting');
	}

	@isTest
	static void beforeInsertTest() {
		AbstractTrigger beforeInsert = new AbstractTriggerTest(null,new List<SObject>(),null);
		System.assertEquals('true',''+beforeInsert.isInsert);
		System.assertEquals('false',''+beforeInsert.isUpdate);
		System.assertEquals('false',''+beforeInsert.isDelete);
	}

	@isTest
	static void beforeUpdateTest() {
		AbstractTrigger beforeUpdate = new AbstractTriggerTest(new Map<Id,SObject>(),new List<SObject>(),null);
		System.assertEquals('false',''+beforeUpdate.isInsert);
		System.assertEquals('true',''+beforeUpdate.isUpdate);
		System.assertEquals('false',''+beforeUpdate.isDelete);
	}

	@isTest
	static void beforeOrAfterDeleteTest() {
		AbstractTrigger beforeOrAfterDelete = new AbstractTriggerTest(new Map<Id,SObject>(),null,null);
		System.assertEquals('false',''+beforeOrAfterDelete.isInsert);
		System.assertEquals('false',''+beforeOrAfterDelete.isUpdate);
		System.assertEquals('true',''+beforeOrAfterDelete.isDelete);
	}

	@isTest
	static void afterInsertTest() {
		AbstractTrigger afterInsert = new AbstractTriggerTest(null,null,new Map<Id,SObject>());
		System.assertEquals('true',''+afterInsert.isInsert);
		System.assertEquals('false',''+afterInsert.isUpdate);
		System.assertEquals('false',''+afterInsert.isDelete);
	}

	@isTest
	static void afterUpdateTest() {
		AbstractTriggerTest afterUpdate = new AbstractTriggerTest(new Map<Id,SObject>(),null,new Map<Id,SObject>());
		System.assertEquals('false',''+afterUpdate.isInsert);
		System.assertEquals('true',''+afterUpdate.isUpdate);
		System.assertEquals('false',''+afterUpdate.isDelete);
	}

    @isTest
    static void isActiveWithBooleanMetadata() {
        BooleanMetadata__mdt deactivateAll = [
            select DeveloperName, MasterLabel, Value__c 
            from BooleanMetadata__mdt
        	where DeveloperName='DeactivateAll'];
        BooleanHierarchy__c bh = AbstractTrigger.booleanHierarchyInstance;

        Test.startTest();
        // test we get true as a default when requested in test classes
        Boolean result = AbstractTrigger.isActive(deactivateAll.MasterLabel,true);
        System.assertEquals(true,result);

        AbstractTrigger.booleanSettingMap.clear();
        // test we get false as a default when requested in test classes
        result = AbstractTrigger.isActive(deactivateAll.MasterLabel,false);
        System.assertEquals(false,result);

        // now test as if this is not a test class
        AbstractTrigger.useTestingDefaults = false;
        AbstractTrigger.booleanSettingMap.clear();
        bh.put(deactivateAll.DeveloperName+'__c',Decimal.valueOf(0));
        result = AbstractTrigger.isActive(deactivateAll.MasterLabel,true);
        System.assertEquals(false,result);

        AbstractTrigger.booleanSettingMap.clear();
        bh.put(deactivateAll.DeveloperName+'__c',Decimal.valueOf(1));
        result = AbstractTrigger.isActive(deactivateAll.MasterLabel,false);
        System.assertEquals(true,result);

        AbstractTrigger.booleanSettingMap.clear();
        bh.put(deactivateAll.DeveloperName+'__c',null);
        result = AbstractTrigger.isActive(deactivateAll.MasterLabel,true);
        System.assertEquals(true,result);

        AbstractTrigger.booleanSettingMap.clear();
        result = AbstractTrigger.isActive('__TESTING__',true);
        System.assertEquals(true,result);

        Test.stopTest();
    }
}