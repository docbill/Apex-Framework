// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * Test class for ThreadLock
 * 
 * @version 2020-09-04
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-09-04 US270544 - Created
 */
@IsTest
private class ThreadLockTest {

    static final String KEY1 = 'KEY1';
    static final String KEY2 = 'KEY2';

    @IsTest
    static void lockAndUnlockTest() {
        System.assertEquals(false,ThreadLock.isLocked(KEY1),'ThreadLock.isLocked(KEY1): No thread should be locked at first');
        System.assertEquals(false,ThreadLock.isLocked(KEY2),'ThreadLock.isLocked(KEY2): No thread should be locked at first');
        System.assertEquals(false,ThreadLock.unlock(KEY1),'ThreadLock.unlock(KEY1)');
        System.assertEquals(false,ThreadLock.unlock(KEY2),'ThreadLock.unlock(KEY2)');
        System.assertEquals(true,ThreadLock.lock(KEY1),'ThreadLock.unlock(KEY1)');
        System.assertEquals(true,ThreadLock.isLocked(KEY1),'ThreadLock.isLocked(KEY1)');
        System.assertEquals(false,ThreadLock.isLocked(KEY2),'ThreadLock.isLocked(KEY2)');
        System.assertEquals(true,ThreadLock.lock(KEY2),'ThreadLock.unlock(KEY2)');
        System.assertEquals(true,ThreadLock.isLocked(KEY1),'ThreadLock.isLocked(KEY1)');
        System.assertEquals(true,ThreadLock.isLocked(KEY2),'ThreadLock.isLocked(KEY2)');
        System.assertEquals(true,ThreadLock.unlock(KEY1),'ThreadLock.unlock(KEY1)');
        System.assertEquals(false,ThreadLock.isLocked(KEY1),'ThreadLock.isLocked(KEY1)');
        System.assertEquals(true,ThreadLock.isLocked(KEY2),'ThreadLock.isLocked(KEY2)');
        System.assertEquals(true,ThreadLock.unlock(KEY2),'ThreadLock.unlock(KEY2)');
        System.assertEquals(false,ThreadLock.isLocked(KEY1),'ThreadLock.isLocked(KEY1)');
        System.assertEquals(false,ThreadLock.isLocked(KEY2),'ThreadLock.isLocked(KEY2)');
    }
}
