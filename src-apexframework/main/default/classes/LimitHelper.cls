// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * This Class implements some useful limit utilities.  One example on how to use this
 * call is you write your trigger methods to look something like:
 * 
 * <pre>
 *    public void salesAccountUpdate() {
 *        try {
 *           if(newList.size() > 1) {
 *               LimitHelper.push(SALES_ACCOUNT_UPDATE_SETTING);
 *           }
 *           ...
 *        }
 *        catch(LimitHelper.LimitsException ex) {
 *           ...
 *        }
 *        finally {
 *            if(newList.size() > 1) {
 *                LimitHelper.pop(SALES_ACCOUNT_UPDATE_SETTING);
 *            }
 *        }
 *    }
 * </pre>
 * 
 * The catch exception or an after trigger is where you can add code to use deferred
 * processing to handle one record at the time so you do not hit the limits.
 * 
 * The LimitHelper name you are pushing and poping is the master label of the Limit Reserves
 * metadata type record that defines what how much time you reserving.
 * 
 * Then in order for this code to work there needs to be calls to the LimitHepler class to
 * check the limits periodically.  For example, immediately before a query you could call:
 * 
 * <pre>
 * (new LimitHelper()).setQueries(1).checkLimits( null);
 * </pre>
 * 
 * This is saying check the limits and make sure we have one query available beyound the
 * reserve.  If we do not either return an Exception or throw an exception.  The null
 * argument is the boolean that tells the helper if it should throw the exception.  If you
 * pass true, it will throw the exception.  If you pass false, it will return the exception.
 * Using a null value is equivalent to:
 * 
 * <pre>
 * (new LimitHelper()).setQueries(1).checkLimits( LimitHelper.throwsExceptionDefault );
 * </pre>
 * 
 * There are a series of DatabaseHelper.safe* methods that can be used to automatically
 * check the limits when performing DML operations.  e.g.
 * 
 * <pre>
 * for(DatabaseHelper.Result r : new DatabaseHelper().safeInsert(insertList)) {
 *     if(r.isSuccess()) {
 *         ...
 *     }
 * }
 * </pre>
 * 
 * By default we are checking a whole bunch of limits each time, but there are static
 * methods in the LimitHelper class for checking individual limits.
 * 
 * @version 2020-08-13
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-08-13 US266008 - Created
 * @since 2021-04-28 - Add queueable jobs limits check
 */
public without sharing class LimitHelper {
    /**
     * This is basically a setting to determine if checks will throw an exception
     * when the throwsException flag is null.  We initialise this to false so the
     * checks can safely be added to triggers that cannot properly deal with the exception
     * from all places dml is performed, and activated by code that can support the
     * exceptions.
     */
    public static Boolean throwsExceptionDefault {
        get {
            return (throwsExceptionDefault == true)
                || (throwsExceptionDefault == null && reservedList.size() > 1);
        }
        set;
    }

    // Keep track of the limit values reserved
    @TestVisible
    private static List<Object> reservedList = (new List<Object>{ null });

    /**
     * Reserve the values specified by Limit_Reserve__mdt givin my the masterLabel
     * 
     * @param masterLabel
     */
    public static void push(String masterLabel) {
        Object value = masterLabel;
        for(Limit_Reserve__mdt r : [
            select 
                MasterLabel,
                cpuTime__c,
                dmlStatements__c,
                dmlRows__c,
                queries__c,
                queueableJobs__c
            from Limit_Reserve__mdt
            where MasterLabel = :masterLabel
            limit 1 ])
        {
            value = r;
            if(r.cpuTime__c != null) {
                cpuTimeReserved += r.cpuTime__c.intValue();
            }
            if(r.dmlStatements__c != null) {
                dmlStatementsReserved += r.dmlStatements__c.intValue();
            }
            if(r.dmlRows__c != null) {
                dmlRowsReserved += r.dmlRows__c.intValue();
            }
            if(r.queries__c != null) {
                queriesReserved += r.queries__c.intValue();
            }
            if(r.queueableJobs__c != null) {
                queueableJobsReserved += r.queueableJobs__c.intValue();
            }
        }
        reservedList.add(0,value);
    }

    /**
     * Unreserve the values specified by Limit_Reserve__mdt givin my the masterLabel.  If
     * other values have been reserved as well afterwards, pop those values as well.
     * 
     * @param masterLabel
     */
    public static void pop(String masterLabel) {
        while(reservedList.size() > 1) {
            String xmasterLabel = null;
            Object value = reservedList.remove(0);
            if(value instanceof Limit_Reserve__mdt) {
                Limit_Reserve__mdt r = (Limit_Reserve__mdt)value;
                xmasterLabel = r.MasterLabel;
                if(r.cpuTime__c != null) {
                    cpuTimeReserved -= r.cpuTime__c.intValue();
                }
                if(r.dmlStatements__c != null) {
                    dmlStatementsReserved -= r.dmlStatements__c.intValue();
                }
                if(r.dmlRows__c != null) {
                    dmlRowsReserved -= r.dmlRows__c.intValue();
                }
                if(r.queries__c != null) {
                    queriesReserved -= r.queries__c.intValue();
                }
                if(r.queueableJobs__c != null) {
                    queueableJobsReserved -= r.queueableJobs__c.intValue();
                }
            }
            else {
                xmasterLabel = String.valueOf(value);
            }
            if(masterLabel == null || masterLabel == xmasterLabel) {
                break;
            }
        }
    }

    // How much CPU time in ms do we need for the next operation?
    private Integer cpuTime = 0;

    /**
     * Set how much cpu time is needed for the next call.
     * 
     * @param value
     * @return this
     */
    public LimitHelper setCpuTime(Integer value) {
        cpuTime = value;
        return this;
    }

    // How many dml statements are needed for the next call?
    private Integer dmlStatements = 0;

    /**
     * Set how many dml statements are needed for the next call?
     * 
     * @param value
     * @return this
     */
    public LimitHelper setDmlStatements(Integer value) {
        dmlStatements = value;
        return this;
    }

    // How many dml rows are needed for the next call?
    private Integer dmlRows = 0;

    /**
     * Set how many dml rows are needed for the next call?
     * 
     * @param value
     * @return this
     */
    public LimitHelper setDmlRows(Integer value) {
        dmlRows = value;
        return this;
    }

    // How many queries are needed for the next call?
    private Integer queries = 0;

    /**
     * Set how many queries are needed for the next call?
     * 
     * @param value
     * @return this
     */
    public LimitHelper setQueries(Integer value) {
        queries = value;
        return this;
    }

    // How many queueableJobs are needed for the next call?
    private Integer queueableJobs = 0;

    /**
     * Set how many queueableJobs are needed for the next call?
     * 
     * @param value
     * @return this
     */
    public LimitHelper setQueueableJobs(Integer value) {
        queueableJobs = value;
        return this;
    }


    /**
     * Check all the assigned limit values.
     * 
     * @param throwsException a null is equivalent to throwsExceptionDefault 
     */
    public String checkLimits(Boolean throwsException) {
        String message = null;
        try {
            checkLimitCPUTime(cpuTime,true);
            checkLimitDMLStatements(dmlStatements,true);
            checkLimitDMLRows(dmlRows,true);
            checkLimitQueries(queries,true);
            checkLimitQueueableJobs(queueableJobs,true);
        }
        catch(LimitsException ex) {
            if(throwsException == true 
                || (throwsException == null && throwsExceptionDefault == true) )
            {
                throw ex;
            }
            message = ex.getMessage();
        }
        return message;
    }

    /**
     * Since CPU checks are not regularly called you should probably reserve at least
     * 100 ms in order for this to work.  A negative value deactivates this check.
     */
    public static Integer cpuTimeReserved=-1;

    /**
     * Called to check just the cpu time limit.
     * 
     * @param cpuTimeRequired
     * @param throwsException a null is equivalent to throwsExceptionDefault
     */
    public static String checkLimitCPUTime(Integer cpuTimeRequired,Boolean throwsException) {
        if(cpuTimeRequired != null && cpuTimeReserved >= 0) {
            Integer cpuTime = cpuTimeRequired+Limits.getCpuTime();
            Integer cpuTimeLimit = Limits.getLimitCpuTime()-cpuTimeReserved;
            System.debug('checkLimitCPUTime '+cpuTime+' out of '+cpuTimeLimit);
            if(cpuTime >= cpuTimeLimit) {
                return createLimitsMessage('CPU Time',cpuTime,cpuTimeLimit,throwsException);
            }
        }
        return null;
    }

    /** 
     * You can specify exactly the number of rows you want to reserve.  A negative value
     * will deactivate this check.
     */
    public static Integer dmlRowsReserved = 0;

    /**
     * Called to check just the dml row limit.
     * 
     * @param dmlRowsRequired
     * @param throwsException a null is equivalent to throwsExceptionDefault
     */
    public static String checkLimitDMLRows(Integer dmlRowsRequired,Boolean throwsException) {
        if(dmlRowsRequired != null && dmlRowsReserved >= 0) {
            Integer dmlRows = dmlRowsRequired+Limits.getDMLRows();
            Integer dmlRowsLimit = Limits.getLimitDMLRows()-dmlRowsReserved;
            System.debug('checkLimitDMLRows '+dmlRows+' out of '+dmlRowsLimit);
            if(dmlRows > dmlRowsLimit) {
                return createLimitsMessage('DML Rows',dmlRows,dmlRowsLimit,throwsException);
            }
        }
        return null;
    }

    /** 
     * You can specify exactly the number of statements you want to reserve.  A negative value
     * will deactivate this check.
     */
    public static Integer dmlStatementsReserved = 0;

    /**
     * Called to check just the dml statements limit.
     * 
     * @param dmlStatementsRequired
     * @param throwsException a null is equivalent to throwsExceptionDefault
     */
    public static String checkLimitDMLStatements(Integer dmlStatementsRequired,Boolean throwsException) {
        if(dmlStatementsRequired != null && dmlStatementsReserved >= 0) {
            Integer dmlStatements = dmlStatementsRequired+Limits.getDMLStatements();
            Integer dmlStatementsLimit = Limits.getLimitDMLStatements()-dmlStatementsReserved;
            System.debug('checkLimitDMLStatements '+dmlStatements+' out of '+dmlStatementsLimit);
            if(dmlStatements > dmlStatementsLimit) {
                return createLimitsMessage('DML Statements',dmlStatements,dmlStatementsLimit,throwsException);
            }
        }
        return null;
    }

    /** 
     * You can specify exactly the number of queries you want to reserve.  A negative value
     * will deactivate this check.
     */
    public static Integer queriesReserved = 0;

    /**
     * Called to check just the dml statements limit.
     * 
     * @param queriesRequired
     * @param throwsException a null is equivalent to throwsExceptionDefault
     */
    public static String checkLimitQueries(Integer queriesRequired,Boolean throwsException) {
        if(queriesRequired != null && queriesReserved > 0) {
            Integer queries = queriesRequired+Limits.getQueries();
            Integer queriesLimit = Limits.getLimitQueries()-queriesReserved;
            System.debug('checkLimitQueries '+queries+' out of '+queriesLimit);
            if(queries > queriesLimit) {
                return createLimitsMessage('Queries',queries,queriesLimit,throwsException);
            }
        }
        return null;
    }

    /** 
     * You can specify exactly the number of queueableJobs you want to reserve.  A negative value
     * will deactivate this check.
     */
    public static Integer queueableJobsReserved = 0;

    /**
     * Called to check just the queueable jobs limit.
     * 
     * @param queueableJobsRequired
     * @param throwsException a null is equivalent to throwsExceptionDefault
     */
    public static String checkLimitQueueableJobs(Integer queueableJobsRequired,Boolean throwsException) {
        if(queueableJobsRequired != null && queueableJobsReserved >= 0) {
            Integer queueableJobs = queueableJobsRequired+Limits.getQueueableJobs();
            Integer queueableJobsLimit = 0;
            if((! Test.isRunningTest())||(! System.isQueueable())) {
                queueableJobsLimit = Limits.getLimitQueueableJobs()-queueableJobsReserved;
            }
            System.debug('checkLimitQueueableJobs '+queueableJobs+' out of '+queueableJobsLimit);
            if(queueableJobs > queueableJobsLimit) {
                return createLimitsMessage('Queueable Jobs',queueableJobs,queueableJobsLimit,throwsException);
            }
        }
        return null;
    }

    // format the limits message, and throw it as an exception when required to do so
    private static String createLimitsMessage(
        String limitString,
        Object requiredValue,
        Object allowedValue,
        Boolean throwsException
    ) {
        String message = 'Limits: '+limitString+': '+requiredValue+' out of '+allowedValue;
        if(throwsException == true 
            || (throwsException == null && throwsExceptionDefault == true))
        {
            throw new LimitsException(message);
        }
        System.debug(LoggingLevel.ERROR,message);
        return message;
    }

    /**
     * Exception for a limit check failure.
     */
    public class LimitsException extends Exception {}
}
