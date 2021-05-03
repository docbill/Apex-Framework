/**
 * This Class allows recursive dml updates via the queueable interface.
 *
 * @version 2021-04-28
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2021-04-28 - Separated from the DatabaseHelper class
 */
public class DatabaseHelperQueueable implements Queueable {
    static List<DatabaseHelperQueueable> databaseHelperQueueableList = null;

    DatabaseHelper helper;
    DatabaseHelper.DMLOperation op;
    List<List<SObject>> recordsList;
    List<DatabaseHelperQueueable> queueableList;
    Integer enqueueScope;
    Map<String,Boolean> booleanSettingMap;
    Map<String,Boolean> overrideSettingMap;

    public DatabaseHelperQueueable(
        DatabaseHelper helper,
        DatabaseHelper.DMLOperation op,
        List<List<SObject>> recordsList)
    {
        this.helper = helper;
        this.op = op;
        this.recordsList = recordsList;
        this.enqueueScope = helper.getEnqueueScope();
    }

    @TestVisible
    static List<DatabaseHelperQueueable> enqueueJob(List<DatabaseHelperQueueable> queueableList) {
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

    public void enqueueJob() {
        if(databaseHelperQueueableList == null) {
            databaseHelperQueueableList = new List<DatabaseHelperQueueable>();
        }
        if(! recordsList.isEmpty()) {
            databaseHelperQueueableList.add(this);
        }
        if(! databaseHelperQueueableList.isEmpty()) {
            final String LOCK_STRING = DatabaseHelper.class.getName();
            if(ThreadLock.lock(LOCK_STRING)) {
                try {
                    this.booleanSettingMap = BooleanValuesHelper.booleanSettingMap;
                    this.overrideSettingMap = BooleanValuesHelper.overrideSettingMap;
                    this.queueableList = databaseHelperQueueableList;
                    if(null == (new LimitHelper()).setQueueableJobs(1).checkLimits(! Test.isRunningTest())) {
                        System.debug('2.enqueueJob');
                        System.enqueueJob(this.queueableList[0]);
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
        }
    }

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
        helper.setEnqueueScope(null).dmlStatement(op,currentList);
    }
}