// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description
 * This Class allows recursive dml updates via the queueable interface.
 *
 * @group ApexFramework
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2021-04-28 - Separated from the DatabaseHelper class
 * @since 2021-10-27 US307550 - Fixed enqueueing multiple dml calls
 * @since 2022-09-09 update for ApexDox commenting
 * @since 2022-11-09 support async callbacks
 */
public class DatabaseHelperQueueable implements Queueable {
    private static List<DatabaseHelperQueueable> databaseHelperQueueableList = null;

    private DatabaseHelperAsyncHelper helper;
    private DatabaseHelper.DMLOperation op;
    private List<List<SObject>> recordsList = new List<List<SObject>>();
    private List<DatabaseHelperQueueable> queueableList;
    private Integer enqueueScope;
    private Map<String,Boolean> booleanSettingMap;
    private Map<String,Boolean> overrideSettingMap;

    /**
     * @description 
     * Constructor used by the DatabaseHelper
     * 
     * @param helper the helper class using this queueable instance
     * @param op the dml operation being performed
     * @param recordsList list of records lists being daisychained
     */
    public DatabaseHelperQueueable(
        DatabaseHelper helper,
        DatabaseHelper.DMLOperation op,
        List<List<SObject>> recordsList)
    {
        this.helper = new DatabaseHelperAsyncHelper(helper);
        this.op = op;
        this.enqueueScope = helper.getEnqueueScope();
        for(List<SObject> records : recordsList) {
            if(records != null && ! records.isEmpty()) {
                this.recordsList.add(records);
            }
        }
    }

    @TestVisible
    private static List<DatabaseHelperQueueable> enqueueJob(List<DatabaseHelperQueueable> queueableList) {
        if(! queueableList.isEmpty()) {
            queueableList[0].queueableList = queueableList;
            queueableList[0].booleanSettingMap = BooleanValuesHelper.booleanSettingMap;
            queueableList[0].overrideSettingMap = BooleanValuesHelper.overrideSettingMap;
            if(null == (new LimitHelper()).setQueueableJobs(1).checkLimits(! Test.isRunningTest())) {
                System.debug('1.enqueueJob');
                System.enqueueJob(queueableList[0]);
            }
            queueableList = null;
        }
        return queueableList;
    }

    /**
     * @description 
     * Enqueue the list of daisy chained jobs.
     */
    public void enqueueJob() {
        if(databaseHelperQueueableList == null) {
            databaseHelperQueueableList = new List<DatabaseHelperQueueable>();
        }
        if(! recordsList.isEmpty()) {
            databaseHelperQueueableList.add(this);
        }
        for(DatabaseHelperQueueable dhq : databaseHelperQueueableList) {
            final String LOCK_STRING = DatabaseHelper.class.getName();
            if(ThreadLock.lock(LOCK_STRING)) {
                try {
                    dhq.booleanSettingMap = BooleanValuesHelper.booleanSettingMap;
                    dhq.overrideSettingMap = BooleanValuesHelper.overrideSettingMap;
                    dhq.queueableList = databaseHelperQueueableList;
                    if(null == (new LimitHelper()).setQueueableJobs(1).checkLimits(! Test.isRunningTest())) {
                        System.debug('2.enqueueJob');
                        System.enqueueJob(dhq);
                    }
                }
                finally {
                    ThreadLock.unlock(LOCK_STRING);
                    this.booleanSettingMap = null;
                    this.overrideSettingMap = null;
                    this.queueableList = null;
                    databaseHelperQueueableList = null;
                    recordsList.clear();
                }
            }
            break;
        }
    }

    /**
     * @description 
     * Part of the Queueable interface. Pull off the first list of records
     * for dml, enqueue the remaining records, and then actually perform the dml.
     *
     * @param context ignored
     */
    public void execute(QueueableContext context) {
        List<SObject> currentList = recordsList.remove(0);
        if(recordsList.isEmpty()) {
            this.queueableList.remove(0);
        }
        BooleanValuesHelper.booleanSettingMap.clear();
        BooleanValuesHelper.booleanSettingMap.putAll(this.booleanSettingMap);
        BooleanValuesHelper.overrideSettingMap.clear();
        BooleanValuesHelper.overrideSettingMap.putAll(this.overrideSettingMap);
        this.queueableList = enqueueJob(this.queueableList);
        this.booleanSettingMap = null;
        this.overrideSettingMap = null;
        helper.dmlStatement(op,currentList);
    }
}
