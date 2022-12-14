// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description
 * This is a class for TriggerArguments
 * <br /><br />
 * 
 * All values are assigned in the constructor as final.
 * 
 * @group ApexFrameworkTest
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-11-12 Created
 * @since 2022-09-09 update for ApexDox commenting
 */
@isTest
public class TriggerArgumentsTest {
    static List<User> users = (new List<User>{new User(LastName='Test New User')});
    static List<User> newList = (new List<User>{new User(Id=UserInfo.getUserId(),LastName='Test New User')});
    static List<User> oldList = (new List<User>{new User(Id=UserInfo.getUserId(),LastName='Test Old User')});
    static Map<Id,User> newMap = new Map<Id,User>(newList);
    static Map<Id,User> oldMap = new Map<Id,User>(oldList);

    /**
     * @description 
     * This is a means to method to return a test set of arguments for your desired trigger type.
     * 
     * @todo replace trigger type with operation type
     *  
     * @param trigType 
     * @return  `Map<String,Object>`
     */
    public static Map<String,Object> createArgs(TriggerArguments.TriggerType trigType ) {
        Map<String,Object> args = null;
        switch on trigType {
            when BEFORE_INSERT {
                args = TriggerArguments.createBeforeInsert(users.clone()).callableArguments;
            }
            when AFTER_INSERT {
                args = TriggerArguments.createAfterInsert(newMap.clone()).callableArguments;
            }
            when BEFORE_UPDATE {
                args = TriggerArguments.createBeforeUpdate(oldMap.clone(),newList.clone()).callableArguments;
            }
            when AFTER_UPDATE {
                args = TriggerArguments.createAfterUpdate(oldMap.clone(),newMap.clone()).callableArguments;
            }
            when BEFORE_DELETE {
                args = TriggerArguments.createBeforeDelete(oldMap.clone()).callableArguments;
            }
            when AFTER_DELETE {
                args = TriggerArguments.createAfterDelete(oldMap.clone()).callableArguments;
            }
            when AFTER_UNDELETE {
                args = TriggerArguments.createAfterUndelete(newMap.clone()).callableArguments;
            }
        }
        return args;
    }

    @isTest
    private static void beforeInsertTest() {
        TriggerArguments ta = TriggerArguments.createBeforeInsert(users.clone());
        System.assertEquals(TriggerArguments.TriggerType.BEFORE_INSERT,ta.triggerTypeValue,'triggerTypeValue');

        System.assertEquals(users,ta.newList,TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(users,(List<User>)ta.callableArguments.get(TriggerArguments.NEW_LIST_KEY),TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(null,ta.newMap,TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(null,(Map<Id,User>)ta.callableArguments.get(TriggerArguments.NEW_MAP_KEY),TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(null,ta.oldList,TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(null,(List<User>)ta.callableArguments.get(TriggerArguments.OLD_LIST_KEY),TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(null,ta.oldMap,TriggerArguments.OLD_MAP_KEY);
        System.assertEquals(null,(Map<Id,User>)ta.callableArguments.get(TriggerArguments.OLD_MAP_KEY),TriggerArguments.OLD_MAP_KEY);

        System.assertEquals(User.class.getName(),ta.targetObjectType,TriggerArguments.TARGET_OBJECT_TYPE_KEY);
        System.assertEquals(User.class.getName(),ta.callableArguments.get(TriggerArguments.TARGET_OBJECT_TYPE_KEY),TriggerArguments.TARGET_OBJECT_TYPE_KEY);

        System.assertEquals(true,ta.isBefore,TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_BEFORE_KEY),TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(false,ta.isAfter,TriggerArguments.IS_AFTER_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_AFTER_KEY),TriggerArguments.IS_AFTER_KEY);

        System.assertEquals(false,ta.isUpdate,TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UPDATE_KEY),TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(false,ta.isDelete,TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_DELETE_KEY),TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,ta.isUndelete,TriggerArguments.IS_UNDELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UNDELETE_KEY),TriggerArguments.IS_UNDELETE_KEY);
        System.assertEquals(true,ta.isInsert,TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_INSERT_KEY),TriggerArguments.IS_INSERT_KEY);

        System.assertEquals(null,ta.getNewValue(newList[0].Id),'getNewValue('+newList[0].Id+')');
        System.assertEquals(null,ta.getOldValue(newList[0].Id),'getOldValue('+newList[0].Id+')');
    } 

    @isTest
    private static void afterInsertTest() {
        TriggerArguments ta = TriggerArguments.createAfterInsert(newMap.clone());
        System.assertEquals(TriggerArguments.TriggerType.AFTER_INSERT,ta.triggerTypeValue,'triggerTypeValue');

        System.assertEquals(JSON.serialize(newList),JSON.serialize(ta.newList),TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(JSON.serialize(newList),JSON.serialize(ta.callableArguments.get(TriggerArguments.NEW_LIST_KEY)),TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(newMap,ta.newMap,TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(newMap,(Map<Id,User>)ta.callableArguments.get(TriggerArguments.NEW_MAP_KEY),TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(null,ta.oldList,TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(null,(List<User>)ta.callableArguments.get(TriggerArguments.OLD_LIST_KEY),TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(null,ta.oldMap,TriggerArguments.OLD_MAP_KEY);
        System.assertEquals(null,(Map<Id,User>)ta.callableArguments.get(TriggerArguments.OLD_MAP_KEY),TriggerArguments.OLD_MAP_KEY);

        System.assertEquals(User.class.getName(),ta.targetObjectType,TriggerArguments.TARGET_OBJECT_TYPE_KEY);
        System.assertEquals(User.class.getName(),ta.callableArguments.get(TriggerArguments.TARGET_OBJECT_TYPE_KEY),TriggerArguments.TARGET_OBJECT_TYPE_KEY);

        System.assertEquals(false,ta.isBefore,TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_BEFORE_KEY),TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(true,ta.isAfter,TriggerArguments.IS_AFTER_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_AFTER_KEY),TriggerArguments.IS_AFTER_KEY);

        System.assertEquals(false,ta.isUpdate,TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UPDATE_KEY),TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(true,ta.isInsert,TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_INSERT_KEY),TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(false,ta.isDelete,TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_DELETE_KEY),TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,ta.isUndelete,TriggerArguments.IS_UNDELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UNDELETE_KEY),TriggerArguments.IS_UNDELETE_KEY);
        System.assertNotEquals(null,ta.getNewValue(newList[0].Id),'getNewValue('+newList[0].Id+')');
        System.assertEquals(null,ta.getOldValue(newList[0].Id),'getOldValue('+newList[0].Id+')');
    } 

    @isTest
    private static void beforeUpdateTest() {
        TriggerArguments ta = TriggerArguments.createBeforeUpdate(oldMap.clone(),newList.clone());
        System.assertEquals(TriggerArguments.TriggerType.BEFORE_UPDATE,ta.triggerTypeValue,'triggerTypeValue');

        System.assertEquals(newList,ta.newList,TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(newList,(List<User>)ta.callableArguments.get(TriggerArguments.NEW_LIST_KEY),TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(JSON.serialize(newMap),JSON.serialize(ta.newMap),TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(JSON.serialize(newMap),JSON.serialize(ta.callableArguments.get(TriggerArguments.NEW_MAP_KEY)),TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(JSON.serialize(oldList),JSON.serialize(ta.oldList),TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(JSON.serialize(oldList),JSON.serialize(ta.callableArguments.get(TriggerArguments.OLD_LIST_KEY)),TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(oldMap,ta.oldMap,TriggerArguments.OLD_MAP_KEY);
        System.assertEquals(oldMap,(Map<Id,User>)ta.callableArguments.get(TriggerArguments.OLD_MAP_KEY),TriggerArguments.OLD_MAP_KEY);

        System.assertEquals(User.class.getName(),ta.targetObjectType,TriggerArguments.TARGET_OBJECT_TYPE_KEY);
        System.assertEquals(User.class.getName(),ta.callableArguments.get(TriggerArguments.TARGET_OBJECT_TYPE_KEY),TriggerArguments.TARGET_OBJECT_TYPE_KEY);

        System.assertEquals(true,ta.isBefore,TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_BEFORE_KEY),TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(false,ta.isAfter,TriggerArguments.IS_AFTER_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_AFTER_KEY),TriggerArguments.IS_AFTER_KEY);

        System.assertEquals(true,ta.isUpdate,TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UPDATE_KEY),TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(false,ta.isInsert,TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_INSERT_KEY),TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(false,ta.isDelete,TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_DELETE_KEY),TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,ta.isUndelete,TriggerArguments.IS_UNDELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UNDELETE_KEY),TriggerArguments.IS_UNDELETE_KEY);

        System.assertNotEquals(null,ta.getNewValue(newList[0].Id),'getNewValue('+newList[0].Id+')');
        System.assertNotEquals(null,ta.getOldValue(newList[0].Id),'getOldValue('+newList[0].Id+')');
    } 

    @isTest
    private static void beforeUpdateTest2() {
        Map<String,Object> args = ( new Map<String,Object>{
            TriggerArguments.OLD_MAP_KEY => oldMap,
            TriggerArguments.NEW_LIST_KEY => newList,
            TriggerArguments.IS_BEFORE_KEY => true,
            TriggerArguments.TARGET_OBJECT_TYPE_KEY => 'TEST'
        } );
        TriggerArguments ta = new TriggerArguments(args.clone());
        System.assertEquals(TriggerArguments.TriggerType.BEFORE_UPDATE,ta.triggerTypeValue,'triggerTypeValue');

        System.assertEquals(JSON.serialize(newList),JSON.serialize(ta.newList),TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(JSON.serialize(newList),JSON.serialize(ta.callableArguments.get(TriggerArguments.NEW_LIST_KEY)),TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(newMap,(Map<Id,User>)ta.newMap,TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(newMap,(Map<Id,User>)ta.callableArguments.get(TriggerArguments.NEW_MAP_KEY),TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(JSON.serialize(oldList),JSON.serialize(ta.oldList),TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(JSON.serialize(oldList),JSON.serialize(ta.callableArguments.get(TriggerArguments.OLD_LIST_KEY)),TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(oldMap,ta.oldMap,TriggerArguments.OLD_MAP_KEY);
        System.assertEquals(oldMap,(Map<Id,User>)ta.callableArguments.get(TriggerArguments.OLD_MAP_KEY),TriggerArguments.OLD_MAP_KEY);

        System.assertEquals('TEST',ta.targetObjectType,TriggerArguments.TARGET_OBJECT_TYPE_KEY);
        System.assertEquals('TEST',ta.callableArguments.get(TriggerArguments.TARGET_OBJECT_TYPE_KEY),TriggerArguments.TARGET_OBJECT_TYPE_KEY);

        System.assertEquals(true,ta.isBefore,TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_BEFORE_KEY),TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(false,ta.isAfter,TriggerArguments.IS_AFTER_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_AFTER_KEY),TriggerArguments.IS_AFTER_KEY);

        System.assertEquals(true,ta.isUpdate,TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UPDATE_KEY),TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(false,ta.isInsert,TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_INSERT_KEY),TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(false,ta.isDelete,TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_DELETE_KEY),TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,ta.isUndelete,TriggerArguments.IS_UNDELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UNDELETE_KEY),TriggerArguments.IS_UNDELETE_KEY);

        System.assertNotEquals(null,ta.getNewValue(newList[0].Id),'getNewValue('+newList[0].Id+')');
        System.assertNotEquals(null,ta.getOldValue(newList[0].Id),'getOldValue('+newList[0].Id+')');
    } 

    @isTest
    private static void afterUpdateTest() {
        TriggerArguments ta = TriggerArguments.createAfterUpdate(oldMap.clone(),newMap.clone());
        System.assertEquals(TriggerArguments.TriggerType.AFTER_UPDATE,ta.triggerTypeValue,'triggerTypeValue');

        System.assertEquals(JSON.serialize(newList),JSON.serialize(ta.newList),TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(JSON.serialize(newList),JSON.serialize(ta.callableArguments.get(TriggerArguments.NEW_LIST_KEY)),TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(newMap,ta.newMap,TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(newMap,(Map<Id,User>)ta.callableArguments.get(TriggerArguments.NEW_MAP_KEY),TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(JSON.serialize(oldList),JSON.serialize(ta.oldList),TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(JSON.serialize(oldList),JSON.serialize(ta.callableArguments.get(TriggerArguments.OLD_LIST_KEY)),TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(oldMap,ta.oldMap,TriggerArguments.OLD_MAP_KEY);
        System.assertEquals(oldMap,(Map<Id,User>)ta.callableArguments.get(TriggerArguments.OLD_MAP_KEY),TriggerArguments.OLD_MAP_KEY);

        System.assertEquals(User.class.getName(),ta.targetObjectType,TriggerArguments.TARGET_OBJECT_TYPE_KEY);
        System.assertEquals(User.class.getName(),ta.callableArguments.get(TriggerArguments.TARGET_OBJECT_TYPE_KEY),TriggerArguments.TARGET_OBJECT_TYPE_KEY);

        System.assertEquals(false,ta.isBefore,TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_BEFORE_KEY),TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(true,ta.isAfter,TriggerArguments.IS_AFTER_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_AFTER_KEY),TriggerArguments.IS_AFTER_KEY);

        System.assertEquals(true,ta.isUpdate,TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UPDATE_KEY),TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(false,ta.isInsert,TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_INSERT_KEY),TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(false,ta.isDelete,TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_DELETE_KEY),TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,ta.isUndelete,TriggerArguments.IS_UNDELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UNDELETE_KEY),TriggerArguments.IS_UNDELETE_KEY);

        System.assertNotEquals(null,ta.getNewValue(newList[0].Id),'getNewValue('+newList[0].Id+')');
        System.assertNotEquals(null,ta.getOldValue(newList[0].Id),'getOldValue('+newList[0].Id+')');
    } 

    @isTest
    private static void afterUpdateTest2() {
        Map<String,Object> args = new Map<String,Object>{
            TriggerArguments.OLD_LIST_KEY => oldList,
            TriggerArguments.NEW_MAP_KEY => newMap
        };
        TriggerArguments ta = new TriggerArguments(args.clone());
        System.assertEquals(TriggerArguments.TriggerType.AFTER_UPDATE,ta.triggerTypeValue,'triggerTypeValue');

        System.assertEquals(JSON.serialize(newList),JSON.serialize(ta.newList),TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(JSON.serialize(newList),JSON.serialize(ta.callableArguments.get(TriggerArguments.NEW_LIST_KEY)),TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(newMap,ta.newMap,TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(newMap,(Map<Id,User>)ta.callableArguments.get(TriggerArguments.NEW_MAP_KEY),TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(oldList,ta.oldList,TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(oldList,ta.callableArguments.get(TriggerArguments.OLD_LIST_KEY),TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(JSON.serialize(oldMap),JSON.serialize(ta.oldMap),TriggerArguments.OLD_MAP_KEY);
        System.assertEquals(JSON.serialize(oldMap),JSON.serialize(ta.callableArguments.get(TriggerArguments.OLD_MAP_KEY)),TriggerArguments.OLD_MAP_KEY);

        System.assertEquals(User.class.getName(),ta.targetObjectType,TriggerArguments.TARGET_OBJECT_TYPE_KEY);
        System.assertEquals(User.class.getName(),ta.callableArguments.get(TriggerArguments.TARGET_OBJECT_TYPE_KEY),TriggerArguments.TARGET_OBJECT_TYPE_KEY);

        System.assertEquals(false,ta.isBefore,TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_BEFORE_KEY),TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(true,ta.isAfter,TriggerArguments.IS_AFTER_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_AFTER_KEY),TriggerArguments.IS_AFTER_KEY);

        System.assertEquals(true,ta.isUpdate,TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UPDATE_KEY),TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(false,ta.isInsert,TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_INSERT_KEY),TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(false,ta.isDelete,TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_DELETE_KEY),TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,ta.isUndelete,TriggerArguments.IS_UNDELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UNDELETE_KEY),TriggerArguments.IS_UNDELETE_KEY);

        System.assertNotEquals(null,ta.getNewValue(newList[0].Id),'getNewValue('+newList[0].Id+')');
        System.assertNotEquals(null,ta.getOldValue(newList[0].Id),'getOldValue('+newList[0].Id+')');
    } 

    @isTest
    private static void beforeDeleteTest() {
        TriggerArguments ta = TriggerArguments.createBeforeDelete(oldMap.clone());
        System.assertEquals(TriggerArguments.TriggerType.BEFORE_DELETE,ta.triggerTypeValue,'triggerTypeValue');

        System.assertEquals(null,ta.newList,TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(null,(List<User>)ta.callableArguments.get(TriggerArguments.NEW_LIST_KEY),TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(null,ta.newMap,TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(null,ta.callableArguments.get(TriggerArguments.NEW_MAP_KEY),TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(JSON.serialize(oldList),JSON.serialize(ta.oldList),TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(JSON.serialize(oldList),JSON.serialize(ta.callableArguments.get(TriggerArguments.OLD_LIST_KEY)),TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(oldMap,ta.oldMap,TriggerArguments.OLD_MAP_KEY);
        System.assertEquals(oldMap,(Map<Id,User>)ta.callableArguments.get(TriggerArguments.OLD_MAP_KEY),TriggerArguments.OLD_MAP_KEY);

        System.assertEquals(User.class.getName(),ta.targetObjectType,TriggerArguments.TARGET_OBJECT_TYPE_KEY);
        System.assertEquals(User.class.getName(),ta.callableArguments.get(TriggerArguments.TARGET_OBJECT_TYPE_KEY),TriggerArguments.TARGET_OBJECT_TYPE_KEY);

        System.assertEquals(true,ta.isBefore,TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_BEFORE_KEY),TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(false,ta.isAfter,TriggerArguments.IS_AFTER_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_AFTER_KEY),TriggerArguments.IS_AFTER_KEY);

        System.assertEquals(false,ta.isUpdate,TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UPDATE_KEY),TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(false,ta.isInsert,TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_INSERT_KEY),TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(true,ta.isDelete,TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_DELETE_KEY),TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,ta.isUndelete,TriggerArguments.IS_UNDELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UNDELETE_KEY),TriggerArguments.IS_UNDELETE_KEY);

        System.assertEquals(null,ta.getNewValue(newList[0].Id),'getNewValue('+newList[0].Id+')');
        System.assertNotEquals(null,ta.getOldValue(newList[0].Id),'getOldValue('+newList[0].Id+')');
    } 

    @isTest
    private static void afterDeleteTest() {
        TriggerArguments ta = TriggerArguments.createAfterDelete(oldMap.clone());
        System.assertEquals(TriggerArguments.TriggerType.AFTER_DELETE,ta.triggerTypeValue,'triggerTypeValue');

        System.assertEquals(null,ta.newList,TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(null,(List<User>)ta.callableArguments.get(TriggerArguments.NEW_LIST_KEY),TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(null,ta.newMap,TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(null,ta.callableArguments.get(TriggerArguments.NEW_MAP_KEY),TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(JSON.serialize(oldList),JSON.serialize(ta.oldList),TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(JSON.serialize(oldList),JSON.serialize(ta.callableArguments.get(TriggerArguments.OLD_LIST_KEY)),TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(oldMap,ta.oldMap,TriggerArguments.OLD_MAP_KEY);
        System.assertEquals(oldMap,(Map<Id,User>)ta.callableArguments.get(TriggerArguments.OLD_MAP_KEY),TriggerArguments.OLD_MAP_KEY);

        System.assertEquals(User.class.getName(),ta.targetObjectType,TriggerArguments.TARGET_OBJECT_TYPE_KEY);
        System.assertEquals(User.class.getName(),ta.callableArguments.get(TriggerArguments.TARGET_OBJECT_TYPE_KEY),TriggerArguments.TARGET_OBJECT_TYPE_KEY);

        System.assertEquals(false,ta.isBefore,TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_BEFORE_KEY),TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(true,ta.isAfter,TriggerArguments.IS_AFTER_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_AFTER_KEY),TriggerArguments.IS_AFTER_KEY);

        System.assertEquals(false,ta.isUpdate,TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UPDATE_KEY),TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(false,ta.isInsert,TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_INSERT_KEY),TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(true,ta.isDelete,TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_DELETE_KEY),TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,ta.isUndelete,TriggerArguments.IS_UNDELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UNDELETE_KEY),TriggerArguments.IS_UNDELETE_KEY);

        System.assertEquals(null,ta.getNewValue(newList[0].Id),'getNewValue('+newList[0].Id+')');
        System.assertNotEquals(null,ta.getOldValue(newList[0].Id),'getOldValue('+newList[0].Id+')');
    } 

    @isTest
    private static void afterUndeleteTest() {
        TriggerArguments ta = TriggerArguments.createAfterUndelete(newMap.clone());
        System.assertEquals(TriggerArguments.TriggerType.AFTER_UNDELETE,ta.triggerTypeValue,'triggerTypeValue');

        System.assertEquals(JSON.serialize(newList),JSON.serialize(ta.newList),TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(JSON.serialize(newList),JSON.serialize(ta.callableArguments.get(TriggerArguments.NEW_LIST_KEY)),TriggerArguments.NEW_LIST_KEY);
        System.assertEquals(newMap,ta.newMap,TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(newMap,(Map<Id,User>)ta.callableArguments.get(TriggerArguments.NEW_MAP_KEY),TriggerArguments.NEW_MAP_KEY);
        System.assertEquals(null,ta.oldList,TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(null,(List<User>)ta.callableArguments.get(TriggerArguments.OLD_LIST_KEY),TriggerArguments.OLD_LIST_KEY);
        System.assertEquals(null,ta.oldMap,TriggerArguments.OLD_MAP_KEY);
        System.assertEquals(null,ta.callableArguments.get(TriggerArguments.OLD_MAP_KEY),TriggerArguments.OLD_MAP_KEY);

        System.assertEquals(User.class.getName(),ta.targetObjectType,TriggerArguments.TARGET_OBJECT_TYPE_KEY);
        System.assertEquals(User.class.getName(),ta.callableArguments.get(TriggerArguments.TARGET_OBJECT_TYPE_KEY),TriggerArguments.TARGET_OBJECT_TYPE_KEY);

        System.assertEquals(false,ta.isBefore,TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_BEFORE_KEY),TriggerArguments.IS_BEFORE_KEY);
        System.assertEquals(true,ta.isAfter,TriggerArguments.IS_AFTER_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_AFTER_KEY),TriggerArguments.IS_AFTER_KEY);

        System.assertEquals(false,ta.isUpdate,TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UPDATE_KEY),TriggerArguments.IS_UPDATE_KEY);
        System.assertEquals(false,ta.isInsert,TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_INSERT_KEY),TriggerArguments.IS_INSERT_KEY);
        System.assertEquals(false,ta.isDelete,TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(false,(Boolean)ta.callableArguments.get(TriggerArguments.IS_DELETE_KEY),TriggerArguments.IS_DELETE_KEY);
        System.assertEquals(true,ta.isUndelete,TriggerArguments.IS_UNDELETE_KEY);
        System.assertEquals(true,(Boolean)ta.callableArguments.get(TriggerArguments.IS_UNDELETE_KEY),TriggerArguments.IS_UNDELETE_KEY);

        System.assertNotEquals(null,ta.getNewValue(newList[0].Id),'getNewValue('+newList[0].Id+')');
        System.assertEquals(null,ta.getOldValue(newList[0].Id),'getOldValue('+newList[0].Id+')');
    } 

    @isTest
    private static void dummyTriggerTest() {
        try {
            TriggerArguments ta = new TriggerArguments(null);
            System.assert(true,'one should never reach this line');
        }
        catch(Exception ex) {
            System.debug('Expected Exception: '+ex);
        }
    }

    @isTest
    private static void getSObjectMapTest() {
        List<SObject> values = (new List<User>{new User(Id=UserInfo.getUserId())});
        Map<Id,SObject> mapToClone = new Map<Id,User>();

        Map<Id,SObject> retval = TriggerArguments.getSObjectMap(null,mapToClone,values);
        System.assertEquals(values.size(),retval.size(),'retval.size()');

        retval = TriggerArguments.getSObjectMap(retval,mapToClone,values);
        System.assertEquals(values.size(),retval.size(),'retval.size()');

        // the following is to test the exception handling
        mapToClone = new Map<Id,Opportunity>();
        retval = TriggerArguments.getSObjectMap(null,mapToClone,values);
        System.assertEquals(null,retval,'retval');
    }
}