// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description
 * Test class for ThreadLock
 * 
 * @group ApexFrameworkTest
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-09-04 US270544 - Created
 * @since 2022-09-09 update for ApexDox commenting
 */
@IsTest
private class ThreadLockTest {

    private static final String KEY1 = 'KEY1';
    private static final String KEY2 = 'KEY2';

    @IsTest
    private static void lockAndUnlockTest() {
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