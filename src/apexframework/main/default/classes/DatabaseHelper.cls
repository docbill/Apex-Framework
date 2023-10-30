// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description
 * This Class implements some useful database utilities.  Many copied from TestDataFactory.  It is pretty dangerious to use these in code, but
 * sometimes you need to deactivate triggers to repair or migrate data.   So these are available to call from anonymous apex...
 *
 * @group ApexFramework
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-08-19 US266008 - Added governor limit checks
 * @since 2021-01-07 US281262 - Added setEnqueueScope for Queuable splitting of dml
 * @since 2021-01-27 workaround stack trace bug
 * @since 2021-02-11 initCause on exceptions
 * @since 2021-03-24 lock on DatabaseHelper.class.getName() when enqueueJob is called
 * @since 2021-03-24 remember in queueable instance boolean values
 * @since 2021-04-27 DE26549 - Increment queue counter
 * @since 2021-10-27 US307550 - Fixed enqueueing multiple dml calls
 * @since 2022-09-09 update for ApexDox commenting
 * @since 2022-11-09 support async callbacks
 * @since 2023-10-30 ECM-19647  Add `setAllowSave` and `fakeUpsert` methods
 */
public with sharing class DatabaseHelper extends DatabaseHelperBase {
    /**
     * @description
     * Set this option so we can get test coverage without doing both and insert and update.
     */
    @TestVisible
    private static Boolean alwaysSetSavePoint = false;

    /**
     * @description
     * Standard Constructor.
     */
    public DatabaseHelper() { }

    /**
     * @description
     * We cannot pass the options to an upsert operation, so a workaround
     * is to assign the options to all the records.
     * 
     * @param recordList
     * @return this
     */
    public DatabaseHelper assignOptions(List<SObject> recordList) {
        for(SObject record : recordList) {
            record.setOptions( this.options );
        }
        return this;
    }

    /**
     * @description
     * Assign a finalizer during asynchronous operations.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setFinializer(System.Finalizer value) {
        this.systemFinalizer = value;
        return this;
    } 

    /**
     * @description
     * Assign the setting for callbacks during asynchronous operations.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setAsyncDeleteCallback(DataSource.AsyncDeleteCallback value) {
        this.deleteCallback = value;
        return this;
    }

    /**
     * @description
     * Assign the setting for callbacks during asynchronous operations.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setAsyncSafeCallback(AsyncSafeCallback value) {
        this.safeCallback = value;
        return this;
    }

    /**
     * @description
     * Assign the setting for callbacks during asynchronous operations.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setAsyncSaveCallback(DataSource.AsyncSaveCallback value) {
        this.saveCallback = value;
        return this;
    }

    /**
     * @description
     * Setting this value causes the dml operation to be performed as
     * a chain of queueable jobs.  Each job performing the dml on the
     * number of records specified.  For example, a value of 1 means each record
     * will be processed in a different queueable job.
     * 
     * A negative value means only the overflow records of
     * the first grouping will be processed in a queueable job.  For example,
     * a value of -200 means the first two hundred records are processed 
     * synchronously, then the remaining records are processed in batches of 200.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setEnqueueScope(Integer value) {
        this.enqueueScope = value;
        return this;
    }

    /**
     * @description
     * Set the OptAllOrNone flag on the dmlOptions.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setOptAllOrNone(Boolean value) {
        this.options.OptAllOrNone = value;
        return this;
    }

    /**
     * @description
     * Set the allowFieldTruncation flag on the dmlOptions.  
     * WARNING: This option is ignored when doing an upsert call.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setAllowFieldTruncation(Boolean value) {
        this.options.AllowFieldTruncation = value;
        return this;
    }

    /**
     * @description
     * Set the `DuplicateRuleHeader.AllowSave` flag on the dmlOptions.  
     * WARNING: This option is ignored when doing an upsert call.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setAllowSave(Boolean value) {
        this.options.DuplicateRuleHeader.AllowSave = value;
        return this;
    }
    
    /**
     * @description
     * Set the dmlOptions.
     * WARNING: Only the `OptAllOrNone` option is used by upsert calls.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setOptions(Database.DMLOptions value) {
        this.options = value;
        return this;
    }

    /**
     * @description
     * Set to disable all triggers that use the Deactivate all triggers
     * that use an isActive check on the DeactivateAll boolean metadata.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setDeactivateTriggers(Boolean value) {
        this.deactivateTriggers = value;
        return this;
    }

    /**
     * @description
     * Set the external id field to use in an upsert.
     * 
     * @param value
     * @return this
     */
    public DatabaseHelper setExternalIDField(Schema.SObjectField value) {
        this.externalIDField = value;
        return this;
    }

    /**
     * @description
     * Called to change the check limits property.
     * A setCheckLimits(null) is equivalent to the 
     * setCheckLimits(LimitHelper.throwsExceptionDefault)
     * immediatly prior to the dml operation.
     * 
     * We only throw the limit exception if optAllOrNothing 
     * is true.
     * 
     * @param value if true we should check the limits.
     * @return this
     */
    public DatabaseHelper setCheckLimits(Boolean value) {
        this.checkLimits = value;
        return this;
    }

    /**
     * @description
     * Called to insert the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Result> safeInsert(List<SObject> recordList) {
        this.legacyMode = false;
        return (List<Result>)this.dmlStatement(DMLOperation.INSERT_OP, recordList);
    }

    /**
     * @description
     * Called to insert the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Database.SaveResult> legacyInsert(List<SObject> recordList) {
        this.legacyMode = true;
        return (List<Database.SaveResult>)this.dmlStatement(DMLOperation.INSERT_OP, recordList);
    }

    /**
     * @description
     * Called to update the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Result> safeUpdate(List<SObject> recordList) {
        this.legacyMode = false;
        return (List<Result>)this.dmlStatement(DMLOperation.UPDATE_OP, recordList);
    }

    /**
     * @description
     * Called to update the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Database.SaveResult> legacyUpdate(List<SObject> recordList) {
        this.legacyMode = true;
        return (List<Database.SaveResult>)this.dmlStatement(DMLOperation.UPDATE_OP, recordList);
    }

    /**
     * @description
     * Called to upsert the recordList.  Please note that
     * upsorts do not user DML Options.  If you need DML Options
     * like allowSave, then you should use `fakeUpsert` instead.
     * 
     * @param recordList
     * @return result list
     */
    public List<Result> safeUpsert(List<SObject> recordList) {
        this.legacyMode = false;
        return (List<Result>)this.dmlStatement(DMLOperation.UPSERT_OP, recordList);
    }

    /**
     * @description
     * Called to insert records without an SFDC Id, and update
     * records that have an SFDC Id.  This will do one more DML
     * operation than a `safeUpsert` and will not user the `externalIDField`.
     * However, the `DML Options` will be used.  If you need an
     * option such as `allowSave` this is the obvious call to use.
     * 
     * A `SavePoint` use used to rollback inserts when `OptAllOrNone` is true.
     * 
     * @param recordList
     * @return result list
     */
    public List<Result> fakeUpsert(List<SObject> recordList) {
        List<Result> retval = new List<DatabaseHelper.Result>();
        Savepoint sp = null;
        try {
            List<Boolean> isInsertList = new List<Boolean>();
            List<SObject> insertList = new List<SObject>();
            List<SObject> updateList = new List<SObject>();
            for(SObject record : recordList) {
                Boolean isInsert = (record?.Id == null);
                (isInsert?insertList:updateList).add(record);
                isInsertList.add(isInsert);
            }
            List<Result> insertResult = safeInsert(recordList);
            if( (this.options.OptAllOrNone == true && ! insertResult.isEmpty() && ! updateList.isEmpty()) 
                || alwaysSetSavePoint
            ) {
                sp = Database.setSavepoint();
            }
            List<Result> updateResult = safeUpdate(recordList);
            for(Boolean isInsert : isInsertList) {
                retval.add((isInsert?insertResult:updateResult).remove(0));
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
     * @description
     * Called to upsert the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Database.UpsertResult> legacyUpsert(List<SObject> recordList) {
        this.legacyMode = true;
        return (List<Database.UpsertResult>)this.dmlStatement(DMLOperation.UPSERT_OP, recordList);
    }

    /**
     * @description
     * Called to delete the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Result> safeDelete(List<SObject> recordList) {
        this.legacyMode = false;
        return (List<Result>)this.dmlStatement(DMLOperation.DELETE_OP, recordList);
    }

    /**
     * @description
     * Called to delete the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Database.DeleteResult> legacyDelete(List<SObject> recordList) {
        this.legacyMode = true;
        return (List<Database.DeleteResult>)this.dmlStatement(DMLOperation.DELETE_OP, recordList);
    }

    /**
     * @description
     * Called to undelete the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Database.UndeleteResult> legacyUndelete(List<SObject> recordList) {
        this.legacyMode = true;
        return (List<Database.UndeleteResult>)this.dmlStatement(DMLOperation.UNDELETE_OP, recordList);
    }

    /**
     * @description
     * Called to undelete the recordList.
     * 
     * @param recordList
     * @return result list
     */
    public List<Result> safeUndelete(List<SObject> recordList) {
        this.legacyMode = false;
        return (List<Result>)this.dmlStatement(DMLOperation.UNDELETE_OP, recordList);
    }

    /**
     * @description
     * Method to check success with out depending on the type of database results.
     * 
     * @param result from a insert,update,upsert,delete,or undelete
     * @return true if success
     */
    public static Boolean isSuccess(Object result) {
        Boolean retval = false;
        if(result instanceof Database.SaveResult) {
            retval = ((Database.SaveResult)result).isSuccess();
        }
        else if(result instanceof Database.UpsertResult) {
            retval = ((Database.UpsertResult)result).isSuccess();
        }
        else if(result instanceof Database.DeleteResult) {
            retval = ((Database.DeleteResult)result).isSuccess();
        }
        else if(result instanceof Database.UndeleteResult) {
            retval = ((Database.UndeleteResult)result).isSuccess();
        }
        else if(result instanceof Result) {
            retval = ((Result)result).isSuccess();
        }
        return retval;
    }

    /**
     * @description
     * Method to get errors with out depending on the type of database results.
     * 
     * @param result from a insert,update,upsert,delete,or undelete
     * @return a list of database errors
     */
    public static List<Database.Error> getErrors(Object result) {
        if(result instanceof Database.SaveResult) {
            return ((Database.SaveResult)result).getErrors();
        }
        if(result instanceof Database.UpsertResult) {
            return ((Database.UpsertResult)result).getErrors();
        }
        if(result instanceof Database.DeleteResult) {
            return ((Database.DeleteResult)result).getErrors();
        }
        if(result instanceof Database.UndeleteResult) {
            return ((Database.UndeleteResult)result).getErrors();
        }
        List<Database.Error> retval = null;
        if(result == null) { 
            retval = new List<Database.Error>();
        }
        return retval;
    }

    /**
     * @description
     * We use an exception class for error, so we can throw if we want and we can
     * get a stack trace.
     * 
     * In order for the getError method to work, this class must have the same memembers 
     * as the Database.Error class.
     */
    public class ResultException extends DatabaseHelperResultException {}

    /**
     * @description
     * This is a class that can use to in leiu of the Database.*Result objects.
     * That way we can add to this set exceptions that were never actually thrown
     * and such.
     */
    public interface Result {

        /**
         * @description
         * Find the record we operated on.
         * 
         * @return record
         */
        SObject getSObject();

        /**
         * @description
         * This returns all errors as Database.Error type.
         * 
         * @return list of all errors
         */
        List<Database.Error> getErrors();

        /**
         * @description
         * This returns all errors as DatabaseHelper.ResultException type.
         * 
         * @return list of all errors
         */
        List<ResultException> getExceptions();

        /**
         * @description
         * Return just the first exception as DatabaseHelper.ResultException type.
         * 
         * @return the first exception or null if there were none
         */
        ResultException getException();

        /**
         * @description
         * What is the id value we operated on?
         * 
         * @return id value
         */
        Id getId();

        /**
         * @description
         * Was the DML successful?
         * 
         * @return true if success
         */
        Boolean isSuccess();

        /**
         * @description
         * Test this was an insert or an upsert that created a record.
         * 
         * @return true if a new record was created
         */
        Boolean isCreated();

        /**
         * @description
         * Query a list of stack traces for each exception.
         * 
         * @return list of stack traces 
         */
        List<String> getStackTraceStrings();

        /**
         * @description
         * Convert the result to a different type.
         * 
         * @param apexType
         * @return converted result
         */
        Object convertResult(System.Type apexType);
    }

    /**
     * @description
     * Similar interface to the `DataSource.AsyncSaveCallback` and `DataSource.AsyncDeleteCallback`.
     * Used to return results from asynchronous updates.
     */
    public interface AsyncSafeCallback {
        /**
         * @description 
         *
         * @param op the dml operation which was performed
         * @param results from all the records at once
         */
        void processResults(DMLOperation op,List<DatabaseHelper.Result> results);
    }
}