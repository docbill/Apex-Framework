/**
 * This Class implements some useful database utilities.  Many copied from TestDataFactory.  It is pretty dangerious to use these in code, but
 * sometimes you need to deactivate triggers to repair or migrate data.   So these are available to call from anonymous apex...
 *
 * @version 2020-08-10
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2018-04-24 Created
 * @since 2020-01-13 Added methods to allow field trunction
 * @since 2020-04-08 US252196 - Added asserts to test isSuccess and getErrors methods
 * @since 2020-08-10 US266008 - Added governor limit checks
 * 
 * @todo update TestDataFactory to call this class, rather than having a duplicate implementation.
 */
public with sharing class DatabaseUtilities {

    /**
     * Called to insert a list of objects with DeactivateAll set to true.
     * 
     * @param recordList
     * @param throwErrors if true will require allOrNone 
     * @return a list of Database.SaveResult
     */
    public static List<Database.SaveResult> insertDeactivateAll(List<SObject> recordList,Boolean throwErrors) {
        return new DatabaseHelper()
            .setOptAllOrNone(throwErrors)
            .setDeactivateTriggers(true)
            .legacyInsert(recordList);
    }

    /**
     * Called to update a list of objects with DeactivateAll set to true.
     * 
     * @param recordList
     * @param throwErrors true if an exception should be thrown for errors
     * @return a list of Database.SaveResult
     */
    public static List<Database.SaveResult> updateDeactivateAll(List<SObject> recordList,Boolean throwErrors) {
        return new DatabaseHelper()
            .setOptAllOrNone(throwErrors)
            .setDeactivateTriggers(true)
            .legacyUpdate(recordList);
    }

    /**
     * Called to check if successful, and if not assign an error.
     * @param result the SaveResult
     * @param record to assign the error to
     * @param the prefix for the error message
     * @return true if successful
     */
    @TestVisible
    public static Boolean updateIsSuccess(Database.SaveResult result, SObject record, String errorMessage) 
    {
        System.debug('updateIsSuccess: result='+result+',record='+record);
        Boolean retval = result.isSuccess();
        if(! retval) {
            record.addError( errorMessage+result.getErrors() );
        }
        return retval;
    }

    /**
     * Called to upsert a list of objects with DeactivateAll set to true.
     * 
     * @param recordList
     * @param throwErrors true if an exception should be thrown for errors
     * @return a list of Database.UpsertResult
     */
    public static List<Database.UpsertResult> upsertDeactivateAll(List<SObject> recordList,Boolean throwErrors) {
        return new DatabaseHelper()
            .setOptAllOrNone(throwErrors)
            .setDeactivateTriggers(true)
            .legacyUpsert(recordList);
    }

    /**
     * Called to delete a list of objects with DeactivateAll set to true.
     * 
     * @param recordList
     * @param throwErrors true if an exception should be thrown for errors
     * @return a list of Database.DeleteResult
     */
    public static List<Database.DeleteResult> deleteDeactivateAll(List<SObject> recordList,Boolean throwErrors) {
        return new DatabaseHelper()
            .setOptAllOrNone(throwErrors)
            .setDeactivateTriggers(true)
            .legacyDelete(recordList);
    }

    /**
     * Called to undelete a list of objects with DeactivateAll set to true.
     * 
     * @param recordList
     * @param throwErrors true if an exception should be thrown for errors
     * @return a list of Database.DeleteResult
     */
    public static List<Database.UndeleteResult> undeleteDeactivateAll(List<SObject> recordList,Boolean throwErrors) {
        return new DatabaseHelper()
            .setOptAllOrNone(throwErrors)
            .setDeactivateTriggers(true)
            .legacyUndelete(recordList);
    }

    /**
     * Called to insert a list of records, while allowing field truncation.
     * 
     * @param recordList
     * @param throwErrors true if an exception should be thrown for errors
     * @return list of save results
     */
    public static List<Database.SaveResult> insertAllowFieldTruncation(List<SObject> recordList, Boolean throwErrors) 
    {
        return new DatabaseHelper()
            .setOptAllOrNone(throwErrors)
            .setAllowFieldTruncation(true)
            .legacyInsert(recordList);  
    }

    /**
     * Called to update a list of records, while allowing field truncation.
     * 
     * @param recordList
     * @param throwErrors true if an exception should be thrown for errors
     * @return list of save results
     */
    public static List<Database.SaveResult> updateAllowFieldTruncation(List<SObject> recordList, Boolean throwErrors) 
    {
        return new DatabaseHelper()
            .setOptAllOrNone(throwErrors)
            .setAllowFieldTruncation(true)
            .legacyUpdate(recordList);  
    }

    /**
     * Called to upsert a list of records, while allowing field truncation.
     * 
     * @param recordList
     * @param throwErrors true if an exception should be thrown for errors
     * @return list of save results
     */
    public static List<Database.UpsertResult> upsertAllowFieldTruncation(List<SObject> recordList, Boolean throwErrors) 
    {
        return new DatabaseHelper()
            .setOptAllOrNone(throwErrors)
            .setAllowFieldTruncation(true)
            .assignOptions(recordList)
            .legacyUpsert(recordList);  
    }

    /**
     * Called to fake an upsert a list of records. Mixing SObject types does not work in an upsert
     * so we have to emulate an upsert by doing an insert and update.   This means we use an extra 
     * DML operation and we return save results instead of upsert results.
     * 
     * @param upsertList
     * @param dmlOptions
     * @return list of save results
     */
    public static List<Database.SaveResult> insertOrUpdate(List<SObject> upsertList, Database.DMLOptions dmlOptions)
    {
        List<Database.SaveResult> retval = new List<Database.SaveResult>();
        List<SObject> insertList = new List<SObject>();
        List<SObject> updateList = new List<SObject>();
        List<Integer> insertIndexList = new List<Integer>();
        List<Integer> updateIndexList = new List<Integer>();
        Integer i=0;
        for(SObject record : upsertList) {
            if(record.Id == null) {
                insertList.add(record);
                insertIndexList.add(i++);
            }
            else {
                updateList.add(record);
                updateIndexList.add(i++);
            }
            retval.add(null);
        }
        Savepoint sp = null;
        if(dmlOptions.optAllOrNone == true && ! insertList.isEmpty() && ! updateList.isEmpty() ) {
            // a DML statement is required for each of setSavepoint, insert, update, and rollback
            LimitHelper.checkLimitDMLStatements(4,null);
            sp = Database.setSavepoint();
        }
        DatabaseHelper dh = new DatabaseHelper().setOptions(dmlOptions);
        for(Database.SaveResult r : dh.legacyUpdate(updateList))
        {
            retval[ updateIndexList.remove(0) ] = r;
        }
        try {
            for(Database.SaveResult r : dh.legacyInsert(insertList))
            {
                retval[ insertIndexList.remove(0) ] = r;
            }
            sp = null;
        }
        finally {
            if(sp != null) {
                Database.rollback(sp);
            }
        }
        return retval;
    }

    /**
     * Called to fake an upsert a list of records. Mixing SObject types does not work in an upsert
     * so we have to emulate an upsert by doing an insert and update.   This means we use an extra 
     * DML operation and we return save results instead of upsert results.
     * 
     * @param upsertList
     * @param allowFieldTruncation true if text fields are automatically truncated
     * @param throwErrors true if an exception should be thrown for errors
     * @return list of save results
     */
    public static List<Database.SaveResult> insertOrUpdate(List<SObject> upsertList, Boolean allowFieldTruncation, Boolean throwErrors)
    {
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.allowFieldTruncation = allowFieldTruncation;
        dmlOptions.optAllOrNone = throwErrors;
        return insertOrUpdate(upsertList,dmlOptions);
    }

    /**
     * This is method that will parse through the database results,
     * remove any records from the results and records list that 
     * failed, and add the error to the errorList.
     * 
     * Example usage:
     * <pre>
     * DatabaseUtilities.ErrorCallback callback = new DatabaseUtilities.SimpleErrorList(new List<String>(),true);
     * List<Database.SaveResult> results = (List<Database.SaveResult>)DatabaseUtilities.filterResults(
     *     Database.insert(records,false),
     *     records,
     *     callback,
     *     'Failed to insert' );
     * </pre>
     * 
     * @param results from the insert,update,upsert,delete,undelete
     * @param records the records passed to the dml operation
     * @param callback the error callback
     * @param errorMessage will be appended with the result errors
     * @return the filtered results
     */
    public static List<Object> filterResults(
        List<Object> results,
        List<SObject> records,
        ErrorCallback callback,
        String errorMessage )
    {
        Iterator<Object> resultIterator = results.clone().iterator();
        Iterator<SObject> recordIterator = records.clone().iterator();
        for(Integer i=0;resultIterator.hasNext() && recordIterator.hasNext();i++)
        {
            Object result = resultIterator.next();
            SObject record = recordIterator.next();
            if( ! DatabaseHelper.isSuccess(result) ) {
                results.remove(i);
                records.remove(i--);
                if(callback != null) {
                    callback.addError(result,record,errorMessage);
                }
            }
        }
        return results;
    }

    /**
     * This is an interface used to assign errors.
     */
    public Interface ErrorCallback {
        /**
         * Called for each error.
         * @param result one of Database.SaveResult, Database.UpsertResult,...
         * @param record the message being operated on
         * @param message to indicate what the error was.
         */
        void addError(Object result,SObject record,String message);
    }

    /**
     * This is a simple implementation of the ErrorCallback interface
     * that simply appends errors to a list.
     */
    public class SimpleErrorList implements ErrorCallback {
        public Boolean appendSObject;
        public List<String> errorList;

        /**
         * Constructor
         * 
         * @param errorList
         * @param appendSObject
         */
        public SimpleErrorList(List<String> errorList,Boolean appendSObject) {
            this.errorList = errorList;
            this.appendSObject = appendSObject;
        }

        /**
         * Called for each error.
         * @param result one of Database.SaveResult, Database.UpsertResult,...
         * @param record the message being operated on
         * @param message to indicate what the error was.
         */
        public void addError(Object result,SObject record,String message) {
            message += ': '+DatabaseHelper.getErrors(result);
            if(appendSObject) {
                message += '\n'+record;
            }
            errorList.add( message );
        }
    }
}