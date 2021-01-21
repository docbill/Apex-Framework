/**
 * This is provided mainly as an example of how to declair a trigger.  Ideally you just
 * have one trigger per object.  But so long as each trigger has a unique name passed in the
 * call method, there is no harm in having multiple triggers calling the TriggerManagement 
 * class for the same SObject.
 * 
 * @version 2020-01-04
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-01-04 Created
 */
trigger AttachmentTriggerManagement on Attachment (before delete, before insert, before update,after delete, after insert, after update, after undelete) {
    new TriggerManagement().call('AttachmentTriggerManagement',null);
}