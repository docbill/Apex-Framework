// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * This is a test class for LimitHelper.
 * 
 * @version 2021-04-28
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-08-18 US268650 - Created
 * @since 2021-04-28 - Add queueableJobs limits check
 */
@IsTest
private class LimitHelperTest {

    static Map<String,Limit_Reserve__mdt> limitReserveMap {
        get {
            if(limitReserveMap == null) {
                limitReserveMap = new Map<String,Limit_Reserve__mdt>();
                for(Limit_Reserve__mdt lr : [
                    select MasterLabel 
                    from Limit_Reserve__mdt ])
                {
                    limitReserveMap.put(lr.MasterLabel,lr);
                }
            }
            return limitReserveMap;
        }
        set;
    }

    @isTest
    static void pushPopTest() {
        System.assertEquals(false,LimitHelper.throwsExceptionDefault,'No value should have been assigned');
        List<String> masterLabels = new List<String>{'MasterLabel value that definitely does not exist'};
        masterLabels.addAll(limitReserveMap.keySet());
    
        System.assertEquals(-1,LimitHelper.cpuTimeReserved,'cpuTimeReserved Default');
        System.assertEquals(0,LimitHelper.dmlStatementsReserved,'dmlStatementsReserved Default');
        System.assertEquals(0,LimitHelper.dmlRowsReserved,'dmlRowsReserved Default');
        System.assertEquals(0,LimitHelper.queriesReserved,'queriesReserved Default');
        System.assertEquals(0,LimitHelper.queueableJobsReserved,'queueableJobsReserved Default');
        System.assertEquals(null,LimitHelper.reservedList[0],LimitHelper.reservedList);
        // push all values
        for(String ml : masterLabels) {
            LimitHelper.push(ml);
            Object obj = LimitHelper.reservedList[0];
            if(limitReserveMap.containsKey(ml)) {
                System.assertEquals(ml.toLowerCase(),((Limit_Reserve__mdt)obj).MasterLabel.toLowerCase(),String.valueOf(obj));
            }
            else {
                System.assertEquals(ml,(String)obj,String.valueOf(obj));
                System.assertEquals(-1,LimitHelper.cpuTimeReserved,'cpuTimeReserved Default');
                System.assertEquals(0,LimitHelper.dmlStatementsReserved,'dmlStatementsReserved Default');
                System.assertEquals(0,LimitHelper.dmlRowsReserved,'dmlRowsReserved Default');
                System.assertEquals(0,LimitHelper.queriesReserved,'queriesReserved Default');
                System.assertEquals(0,LimitHelper.queueableJobsReserved,'queueableJobsReserved Default');
            }
        }
        // pop all values
        for(Integer pos = masterLabels.size();pos > 0;) {
            String ml = masterLabels[--pos];
            Object obj = LimitHelper.reservedList[0];
            LimitHelper.pop(ml);
            if(limitReserveMap.containsKey(ml)) {
                System.assertEquals(ml.toLowerCase(),((Limit_Reserve__mdt)obj).MasterLabel.toLowerCase(),String.valueOf(obj));
            }
            else {
                System.assertEquals(ml,(String)obj,String.valueOf(obj));
            }
            if(! (LimitHelper.reservedList[0] instanceof Limit_Reserve__mdt)) {
                System.assertEquals(-1,LimitHelper.cpuTimeReserved,'cpuTimeReserved Default');
                System.assertEquals(0,LimitHelper.dmlStatementsReserved,'dmlStatementsReserved Default');
                System.assertEquals(0,LimitHelper.dmlRowsReserved,'dmlRowsReserved Default');
                System.assertEquals(0,LimitHelper.queriesReserved,'queriesReserved Default');
                System.assertEquals(0,LimitHelper.queueableJobsReserved,'queueableJobsReserved Default');
            }
        }
        // push all values again
        for(String ml : masterLabels) {
            LimitHelper.push(ml);
            Object obj = LimitHelper.reservedList[0];
            if(limitReserveMap.containsKey(ml)) {
                System.assertEquals(ml.toLowerCase(),((Limit_Reserve__mdt)obj).MasterLabel.toLowerCase(),String.valueOf(obj));
            }
            else {
                System.assertEquals(ml,(String)obj,String.valueOf(obj));
                System.assertEquals(-1,LimitHelper.cpuTimeReserved,'cpuTimeReserved Default');
                System.assertEquals(0,LimitHelper.dmlStatementsReserved,'dmlStatementsReserved Default');
                System.assertEquals(0,LimitHelper.dmlRowsReserved,'dmlRowsReserved Default');
                System.assertEquals(0,LimitHelper.queriesReserved,'queriesReserved Default');
                System.assertEquals(0,LimitHelper.queueableJobsReserved,'queueableJobsReserved Default');
            }
        }
        // pop all values at once
        LimitHelper.pop(masterLabels[0]);
        System.assertEquals(null,LimitHelper.reservedList[0],LimitHelper.reservedList);
        System.assertEquals(-1,LimitHelper.cpuTimeReserved,'cpuTimeReserved Default');
        System.assertEquals(0,LimitHelper.dmlStatementsReserved,'dmlStatementsReserved Default');
        System.assertEquals(0,LimitHelper.dmlRowsReserved,'dmlRowsReserved Default');
        System.assertEquals(0,LimitHelper.queriesReserved,'queriesReserved Default');
        System.assertEquals(0,LimitHelper.queueableJobsReserved,'queueableJobsReserved Default');
    }

    @isTest 
    static void cpuTimeTest() {
        LimitHelper.cpuTimeReserved = Limits.getLimitCpuTime() - 200;
        String message = LimitHelper.checkLimitCPUTime(0,false);
        System.assertEquals(null,message,'Unexpected Limit');

        message = LimitHelper.checkLimitCPUTime(0,null);
        System.assertEquals(null,message,'Unexpected Limit');

        LimitHelper.checkLimitCPUTime(0, true); // no exception should be thrown

        message = LimitHelper.checkLimitCPUTime(201,false);
        System.assertNotEquals(null,message,'Expected Limit');

        message = LimitHelper.checkLimitCPUTime(201,null);
        System.assertNotEquals(null,message,'Expected Limit');

        Exception caughtException = null;
        try {
            message = LimitHelper.checkLimitCPUTime(201,true);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');

        LimitHelper.throwsExceptionDefault = true;

        LimitHelper.checkLimitCPUTime(0, null); // no exception should be thrown

        caughtException=null;
        try {
            message = LimitHelper.checkLimitCPUTime(201,null);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');
    }

    @isTest 
    static void checkLimitsCpuTimeTest() {
        LimitHelper.cpuTimeReserved = Limits.getLimitCpuTime() - 200;
        String message = (new LimitHelper()).setCpuTime(0).checkLimits(false);
        System.assertEquals(null,message,'Unexpected Limit');

        message = (new LimitHelper()).setCpuTime(0).checkLimits(null);
        System.assertEquals(null,message,'Unexpected Limit');

        (new LimitHelper()).setCpuTime(0).checkLimits( true); // no exception should be thrown

        message = (new LimitHelper()).setCpuTime(201).checkLimits(false);
        System.assertNotEquals(null,message,'Expected Limit');

        message = (new LimitHelper()).setCpuTime(201).checkLimits(null);
        System.assertNotEquals(null,message,'Expected Limit');

        Exception caughtException = null;
        try {
            message = (new LimitHelper()).setCpuTime(201).checkLimits(true);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');

        LimitHelper.throwsExceptionDefault = true;

        (new LimitHelper()).setCpuTime(0).checkLimits( null); // no exception should be thrown

        caughtException=null;
        try {
            message = (new LimitHelper()).setCpuTime(201).checkLimits(null);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');
    }

    @isTest 
    static void dmlStatementsTest() {
        LimitHelper.dmlStatementsReserved = Limits.getLimitDmlStatements();
        String message = LimitHelper.checkLimitDmlStatements(0,false);
        System.assertEquals(null,message,'Unexpected Limit');

        message = LimitHelper.checkLimitDmlStatements(0,null);
        System.assertEquals(null,message,'Unexpected Limit');

        LimitHelper.checkLimitDmlStatements(0, true); // no exception should be thrown

        message = LimitHelper.checkLimitDmlStatements(1,false);
        System.assertNotEquals(null,message,'Expected Limit');

        message = LimitHelper.checkLimitDmlStatements(1,null);
        System.assertNotEquals(null,message,'Expected Limit');

        Exception caughtException = null;
        try {
            message = LimitHelper.checkLimitDmlStatements(1,true);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');

        LimitHelper.throwsExceptionDefault = true;

        LimitHelper.checkLimitDmlStatements(0, null); // no exception should be thrown

        caughtException=null;
        try {
            message = LimitHelper.checkLimitDmlStatements(1,null);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');
    }

    @isTest 
    static void checkLimitsDmlStatementsTest() {
        LimitHelper.dmlStatementsReserved = Limits.getLimitDmlStatements();
        String message = (new LimitHelper()).setDmlStatements(0).checkLimits(false);
        System.assertEquals(null,message,'Unexpected Limit');

        message = (new LimitHelper()).setDmlStatements(0).checkLimits(null);
        System.assertEquals(null,message,'Unexpected Limit');

        (new LimitHelper()).setDmlStatements(0).checkLimits( true); // no exception should be thrown

        message = (new LimitHelper()).setDmlStatements(1).checkLimits(false);
        System.assertNotEquals(null,message,'Expected Limit');

        message = (new LimitHelper()).setDmlStatements(1).checkLimits(null);
        System.assertNotEquals(null,message,'Expected Limit');

        Exception caughtException = null;
        try {
            message = (new LimitHelper()).setDmlStatements(1).checkLimits(true);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');

        LimitHelper.throwsExceptionDefault = true;

        (new LimitHelper()).setDmlStatements(0).checkLimits( null); // no exception should be thrown

        caughtException=null;
        try {
            message = (new LimitHelper()).setDmlStatements(1).checkLimits(null);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');
    }

    @isTest 
    static void dmlRowsTest() {
        LimitHelper.dmlRowsReserved = Limits.getLimitDmlRows();
        String message = LimitHelper.checkLimitDmlRows(0,false);
        System.assertEquals(null,message,'Unexpected Limit');

        message = LimitHelper.checkLimitDmlRows(0,null);
        System.assertEquals(null,message,'Unexpected Limit');

        LimitHelper.checkLimitDmlRows(0, true); // no exception should be thrown

        message = LimitHelper.checkLimitDmlRows(1,false);
        System.assertNotEquals(null,message,'Expected Limit');

        message = LimitHelper.checkLimitDmlRows(1,null);
        System.assertNotEquals(null,message,'Expected Limit');

        Exception caughtException = null;
        try {
            message = LimitHelper.checkLimitDmlRows(1,true);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');

        LimitHelper.throwsExceptionDefault = true;

        LimitHelper.checkLimitDmlRows(0, null); // no exception should be thrown

        caughtException=null;
        try {
            message = LimitHelper.checkLimitDmlRows(1,null);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');
    }

    @isTest 
    static void checkLimitsDmlRowsTest() {
        LimitHelper.dmlRowsReserved = Limits.getLimitDmlRows();
        String message = (new LimitHelper()).setDmlRows(0).checkLimits(false);
        System.assertEquals(null,message,'Unexpected Limit');

        message = (new LimitHelper()).setDmlRows(0).checkLimits(null);
        System.assertEquals(null,message,'Unexpected Limit');

        (new LimitHelper()).setDmlRows(0).checkLimits( true); // no exception should be thrown

        message = (new LimitHelper()).setDmlRows(1).checkLimits(false);
        System.assertNotEquals(null,message,'Expected Limit');

        message = (new LimitHelper()).setDmlRows(1).checkLimits(null);
        System.assertNotEquals(null,message,'Expected Limit');

        Exception caughtException = null;
        try {
            message = (new LimitHelper()).setDmlRows(1).checkLimits(true);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');

        LimitHelper.throwsExceptionDefault = true;

        (new LimitHelper()).setDmlRows(0).checkLimits( null); // no exception should be thrown

        caughtException=null;
        try {
            message = (new LimitHelper()).setDmlRows(1).checkLimits(null);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');
    }

    @isTest 
    static void queriesTest() {
        LimitHelper.queriesReserved = Limits.getLimitQueries();
        String message = LimitHelper.checkLimitQueries(0,false);
        System.assertEquals(null,message,'Unexpected Limit');

        message = LimitHelper.checkLimitQueries(0,null);
        System.assertEquals(null,message,'Unexpected Limit');

        LimitHelper.checkLimitQueries(0, true); // no exception should be thrown

        message = LimitHelper.checkLimitQueries(1,false);
        System.assertNotEquals(null,message,'Expected Limit');

        message = LimitHelper.checkLimitQueries(1,null);
        System.assertNotEquals(null,message,'Expected Limit');

        Exception caughtException = null;
        try {
            message = LimitHelper.checkLimitQueries(1,true);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');

        LimitHelper.throwsExceptionDefault = true;

        LimitHelper.checkLimitQueries(0, null); // no exception should be thrown

        caughtException=null;
        try {
            message = LimitHelper.checkLimitQueries(1,null);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');
    }

    @isTest 
    static void checkLimitsQueriesTest() {
        LimitHelper.queriesReserved = Limits.getLimitQueries();
        String message = (new LimitHelper()).setQueries(0).checkLimits(false);
        System.assertEquals(null,message,'Unexpected Limit');

        message = (new LimitHelper()).setQueries(0).checkLimits(null);
        System.assertEquals(null,message,'Unexpected Limit');

        (new LimitHelper()).setQueries(0).checkLimits( true); // no exception should be thrown

        message = (new LimitHelper()).setQueries(1).checkLimits(false);
        System.assertNotEquals(null,message,'Expected Limit');

        message = (new LimitHelper()).setQueries(1).checkLimits(null);
        System.assertNotEquals(null,message,'Expected Limit');

        Exception caughtException = null;
        try {
            message = (new LimitHelper()).setQueries(1).checkLimits(true);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');

        LimitHelper.throwsExceptionDefault = true;

        (new LimitHelper()).setQueries(0).checkLimits( null); // no exception should be thrown

        caughtException=null;
        try {
            message = (new LimitHelper()).setQueries(1).checkLimits(null);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');
    }

    @isTest 
    static void queueableJobsTest() {
        LimitHelper.queueableJobsReserved = Limits.getLimitQueueableJobs();
        String message = LimitHelper.checkLimitQueueableJobs(0,false);
        System.assertEquals(null,message,'Unexpected Limit');

        message = LimitHelper.checkLimitQueueableJobs(0,null);
        System.assertEquals(null,message,'Unexpected Limit');

        LimitHelper.checkLimitQueueableJobs(0, true); // no exception should be thrown

        message = LimitHelper.checkLimitQueueableJobs(1,false);
        System.assertNotEquals(null,message,'Expected Limit');

        message = LimitHelper.checkLimitQueueableJobs(1,null);
        System.assertNotEquals(null,message,'Expected Limit');

        Exception caughtException = null;
        try {
            message = LimitHelper.checkLimitQueueableJobs(1,true);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');

        LimitHelper.throwsExceptionDefault = true;

        LimitHelper.checkLimitQueueableJobs(0, null); // no exception should be thrown

        caughtException=null;
        try {
            message = LimitHelper.checkLimitQueueableJobs(1,null);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');
    }

    @isTest 
    static void checkLimitsQueueableJobsTest() {
        LimitHelper.queueableJobsReserved = Limits.getLimitQueueableJobs();
        String message = (new LimitHelper()).setQueueableJobs(0).checkLimits(false);
        System.assertEquals(null,message,'Unexpected Limit');

        message = (new LimitHelper()).setQueueableJobs(0).checkLimits(null);
        System.assertEquals(null,message,'Unexpected Limit');

        (new LimitHelper()).setQueueableJobs(0).checkLimits( true); // no exception should be thrown

        message = (new LimitHelper()).setQueueableJobs(1).checkLimits(false);
        System.assertNotEquals(null,message,'Expected Limit');

        message = (new LimitHelper()).setQueueableJobs(1).checkLimits(null);
        System.assertNotEquals(null,message,'Expected Limit');

        Exception caughtException = null;
        try {
            message = (new LimitHelper()).setQueueableJobs(1).checkLimits(true);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');

        LimitHelper.throwsExceptionDefault = true;

        (new LimitHelper()).setQueueableJobs(0).checkLimits( null); // no exception should be thrown

        caughtException=null;
        try {
            message = (new LimitHelper()).setQueueableJobs(1).checkLimits(null);
        }
        catch(LimitHelper.LimitsException ex) {
            caughtException = ex;
        }
        System.assertNotEquals(null,caughtException,'Expected a LimitHelper.LimitsException');
    }
}
