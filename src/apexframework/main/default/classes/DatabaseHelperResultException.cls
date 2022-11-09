// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description
 * We use an exception class for error, so we can throw if we want and we can
 * get a stack trace.
 * 
 * In order for the getError method to work, this class must have the same memembers 
 * as the Database.Error class.
 *
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2022-11-09 Created
 */
public abstract without sharing class DatabaseHelperResultException extends Exception {
    private transient Boolean ignoreStackTraceString = false;

    /**
     * @description
     * Generate a stack trace string for the result.
     * @return stack trace
     */
    public String stackTraceString {
        get {
            if(ignoreStackTraceString == true) {
                return null;
            }
            return stackTraceString;
        }
        set {
            if(value == null || value == '()') {
                // stack traces only seem to be complete if we actually
                // catch an exception.  So throw anytype of exception
                // and then we have a stack trace.
                try {
                    Integer.valueOf('catdog');
                }
                catch(Exception ex) {
                    List<String> results = ex.getStackTraceString().split('\n',3);
                    results = new List<String>{ 
                        blankValue(getCause()?.getStackTraceString(),''),
                        results[results.size()-1]
                    };
                    value = String.join(results,'\n').trim();
                }
            }
            stackTraceString = value;
        }
    }

    private static String blankValue(String value,String blank) {
        return String.isBlank(value)?blank:value;
    }

    /**
     * @description 
     * Respective message for this exception
     */
    public String message {
        get{ return getMessage(); }
        set{ setMessage(value); }
    }

    /**
     * @description 
     * If not assigned, the DmlType of the getCause exception
     */
    public StatusCode statusCode {
        get {
            if(statusCode == null) {
                Exception ex = getCause();
                if(ex instanceof DmlException) {
                    statusCode = ((DmlException)ex).getDmlType(0);
                }
            }
            return statusCode;
        }
        set;
    }

    /**
     * @description
     * List of DmlFieldNames associated with this result.
     */
    public String [] fields {
        get {
            if(fields == null) {
                fields = new List<String>();
                Exception ex = getCause();
                if(ex instanceof DmlException) {
                    fields = ((DmlException)ex).getDmlFieldNames(0);
                }
            }
            return fields;
        }
        set;
    }

    /**
     * @description 
     * Get this result as a Database.Error
     * @return a Database.Error copy of this result
     */
    public Database.Error getError() {
        ignoreStackTraceString = true;
        String s = JSON.serialize(this,true);
        ignoreStackTraceString = false;
        return (Database.Error)JSON.deserialize(s,Database.Error.class);
    }

    /**
     * @description 
     * Get method for stack trace string
     * @return the stack trace
     */
    public override String getStackTraceString() {
        return stackTraceString;
    }
}
