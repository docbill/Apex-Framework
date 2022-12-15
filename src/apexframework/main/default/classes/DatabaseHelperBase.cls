// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description
 * This is the core part of the database helper
 *
 * @group ApexFramework
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2022-11-09 support async callbacks
 */
public abstract with sharing class DatabaseHelperBase {
    /**
     * @description 
     * Used internally.
     */
    public enum DMLOperation { INSERT_OP, UPDATE_OP, UPSERT_OP, DELETE_OP, UNDELETE_OP }

    /**
     * @description
     * This is just a wiled guess at the minimum numer of ms we should reserve for a DML
     * Statement.
     */
    private static final Integer MINIMUM_TIME_PER_DML = 10;

    protected Boolean checkLimits = null;
    protected Boolean legacyMode = false;
    protected Boolean deactivateTriggers = false;
    protected Integer enqueueScope = null;
    protected Schema.SObjectField externalIDField = null;

    /**
     * @description asynchronous callback for delete operations
     */
    protected DataSource.AsyncDeleteCallback deleteCallback;

    /**
     * @description asynchronous callback for all operations
     */
    protected DatabaseHelper.AsyncSafeCallback safeCallback;

    /**
     * @description asynchronous callback for save operations
     */
    protected DataSource.AsyncSaveCallback saveCallback;

    /**
     * @description asynchronous finilizer
     */
    protected System.Finalizer systemFinalizer;
    
    /**
     * @description
     * Standard Constructor.
     */
    protected DatabaseHelperBase() {}

    /**
     * @description
     * Retrieve value set for enqueueScope.
     * 
     * @return enqueueScope
     */
    public Integer getEnqueueScope() {
        return this.enqueueScope;
    }

    /**
     * @description
     * The `Database.DMLOptions` that will be used in the `dmlStatement` call.
     */
    protected Database.DMLOptions options {
        get {
            if(options == null) {
                options = new Database.DMLOptions();
                options.OptAllOrNone = false;
            }
            return options;
        }
        set;
    }

    /**
     * @description
     * This performs a database operation, with optional limit checks.  If a limit is hit
     * a custom LimitException is thrown.
     * 
     * @param op dml operation to perform
     * @param recordList to insert
     * @return the results list
     */
    public List<Object> dmlStatement(
        DMLOperation op,
        List<SObject> recordList )
    {
        Integer queueableJobs = 0;
        if(enqueueScope != null && enqueueScope != 0) {
            List<List<SObject>> recordsList = split(recordList,-enqueueScope);
            if(recordsList.size() > 1 || enqueueScope > 0) {
                queueableJobs = 1;
                if((new LimitHelper()).setQueueableJobs(1).checkLimits(false) == null) {
                    if(! recordsList.isEmpty()) {
                        recordList = recordsList.remove(0);
                    }
                    new DatabaseHelperQueueable(this,op,recordsList).enqueueJob();
                }
            }
        }
        Integer requiredDML = 0;
        if(! recordList.isEmpty()) {
            requiredDML = 1;
        }
        Boolean deactivateTriggers = this.deactivateTriggers
            && (requiredDML > 0)
            && ! BooleanValuesHelper.getBooleanValue('DeactivateAll',false);
        if(deactivateTriggers) {
            BooleanValuesHelper.setValuesWhichStartWith('DeactivateAll',true);
        }
        List<Object> retval = null;
        try {
            String limitMessage = null;
            if(checkLimits == true || (checkLimits == null && LimitHelper.throwsExceptionDefault == true)) {
                limitMessage = (new LimitHelper())
                    .setCpuTime(MINIMUM_TIME_PER_DML)
                    .setDmlStatements(requiredDML)
                    .setDmlRows(recordList.size())
                    .setQueueableJobs(queueableJobs)
                    .checkLimits( (options == null || options.optAllOrNone == true) );
            }
            if(limitMessage != null) {
                retval = convertException(op,new LimitHelper.LimitsException(limitMessage),recordList.iterator());
            }
            else {
                switch on op {
                    when INSERT_OP {
                        retval = Database.insert(recordList,options);
                    }
                    when UPDATE_OP {
                        retval = Database.update(recordList,options);
                    }
                    when UPSERT_OP {
                        if(externalIDField != null) {
                            retval = Database.upsert(recordList,externalIdField,(options == null || options.optAllOrNone == true));
                        }
                        else {
                            retval = Database.upsert(recordList,(options == null || options.optAllOrNone == true));
                        }
                    }
                    when DELETE_OP {
                        retval = Database.delete(recordList,(options == null || options.optAllOrNone == true));
                    }
                    when UNDELETE_OP {
                        retval = Database.undelete(recordList,(options == null || options.optAllOrNone == true));
                    }
                }
            }
        }
        finally {
            if(deactivateTriggers) {
                BooleanValuesHelper.setValuesWhichStartWith('DeactivateAll',false);
            }
        }
        return DatabaseHelperResult.convertResultType(op,retval,recordList,legacyMode);
    }

    /**
     * @description 
     * Called to perform our Database operation.
     *
     * @param op Database operation to perform
     * @param currentList of records
     * @return this
     */
    public void dmlStatementUseCallbacks(
        DatabaseHelperBase.DMLOperation op,
        List<SObject> currentList
    ) {
        if(systemFinalizer != null) {
            System.attachFinalizer(systemFinalizer);
        }
        enqueueScope = null;
        legacyMode = (safeCallback == null);
        List<Object> results = dmlStatement(op,currentList);
        if(results instanceof List<DatabaseHelper.Result>) {
            safeCallback?.processResults(op,(List<DatabaseHelper.Result>)results);
        }
        else if(results instanceof List<Database.SaveResult>) {
            for(Database.SaveResult result : (List<Database.SaveResult>)results) {
                saveCallback?.processSave(result);
            }
        }
        else if(results instanceof List<Database.DeleteResult>) {
            for(Database.DeleteResult result : (List<Database.DeleteResult>)results) {
                deleteCallback?.processDelete(result);                        
            }
        }
    }

    /**
     * @description
     * Splits a list into smaller lists no greate than size.
     * If size is negative the first list in the returned array
     * will be empty.
     * 
     * @param records list to split
     * @param size the number of records per list
     * @return a list of records lists of the appropriate size
     */
    @TestVisible
    private static List<List<SObject>> split(List<SObject> records,Integer size) {
        List<List<SObject>> retval = new List<List<SObject>>();
        if(records != null) {
            // DE26549 reworked this logic
            if(size == null || size == 0) {
                retval.add(records);
            }
            else {
                List<SObject> currentList = new List<SObject>();
                Integer remaining=size;
                if(size < 0) {
                    size = -size;
                    remaining = 0;
                }
                for(SObject record : records) {
                    if(record != null) {
                        if(remaining-- < 1) {
                            retval.add(currentList);
                            currentList = new List<SObject>();
                            remaining = size-1; // We count this record right away
                        }
                        currentList.add(record);
                    }
                }
                retval.add(currentList);
            }
        }
        return retval;
    }

    private List<Object> convertException(DMLOperation op,Exception ex,Iterator<SObject> recordIterator) {
        List<DatabaseHelper.Result> retval = new List<DatabaseHelper.Result>();
        while(recordIterator.hasNext()) {
            retval.add(new DatabaseHelperResult(op,ex,recordIterator.next()));
        }
        return retval;
    }
}