// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description 
 * This is a helper class used internally to support callbacks.
 * 
 * @group ApexFramework
 * 
 * @author Bill C Riemers
 * @since 2022-11-09 Created
 */
public without sharing class DatabaseHelperAsyncHelper {
    private DatabaseHelper helper;

    /**
     * @description 
     * Construct with the respective DatabaseHelper.
     *
     * @param helper to use with dml operations
     */
    public DatabaseHelperAsyncHelper(DatabaseHelper helper) {
        this.helper = helper;
    }

    /**
     * @description 
     * Called to perform our Database operation.
     *
     * @param op Database operation to perform
     * @param currentList of records
     * @return this
     */
    public DatabaseHelperAsyncHelper dmlStatement(
        DatabaseHelper.DMLOperation op,
        List<SObject> currentList
    ) {
        setResultType();
        List<Object> results = helper.setEnqueueScope(null).dmlStatement(op,currentList);
        processResults(op,results);
        return this;
    }

    /**
     * @description 
     * Perform a dummy insert to set the result type to match our callback.
     */
    private void setResultType() {
        if(helper.safeCallback != null) {
            helper.safeInsert(new List<SObject>());
        }
        else {
            helper.legacyInsert(new List<SObject>());
        }
    }

    /**
     * @description
     * For each of the results of the respective operation, call the respective callback. 
     *
     * @param op operation that was performed
     * @param results of the database operation
     */
    private void processResults(DatabaseHelper.DMLOperation op,List<Object> results) {
        for(Object result : results) {
            if(result instanceof List<DatabaseHelper.Result>) {
                helper.safeCallback?.processResult(op,(DatabaseHelper.Result)result);
            }
            else {
                switch on op {
                    when INSERT_OP, UPDATE_OP, UPSERT_OP {
                        helper.saveCallback?.processSave((Database.SaveResult)result);
                    }
                    when DELETE_OP {
                        helper.deleteCallback?.processDelete((Database.DeleteResult)result);                        
                    }
                }
            }
        }
    }
}
