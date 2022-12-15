// Copyright Red Hat
// SPDX-License-Identifier: GPL-3.0-only
/**
 * @description
 * Test class for DatabaseHelper.
 *
 * @group ApexFrameworkTest
 * 
 * @author Bill C Riemers <briemers@redhat.com>
 * @since 2020-08-18 US268650 - Created
 * @since 2021-01-07 US281262 - Added setEnqueueScope for Queuable splitting of dml
 * @since 2021-03-30 - Increase test coverage
 * @since 2021-04-27 DE26549 - Added split test
 * @since 2022-09-09 update for ApexDox commenting
 * @since 2022-12-13 update to test async callbacks
 */
@IsTest
private class DatabaseHelperBaseTest {
    /**
     * @description 
     * Check we correctly split lists.
     */
    @isTest
    private static void splitTest() {
        List<Account> accounts = (new List<Account>{
            new Account(Name='1'),
            new Account(Name='2'),
            new Account(Name='3'),
            new Account(Name='4'),
            new Account(Name='5'),
            new Account(Name='6'),
            new Account(Name='7'),
            new Account(Name='8')
        });
        List<List<SObject>> results = DatabaseHelper.split(accounts,null);
        System.assertEquals(1,results.size());
        System.assertEquals(accounts.size(),results[0].size());
        results = DatabaseHelper.split(accounts,0);
        System.assertEquals(1,results.size());
        System.assertEquals(accounts.size(),results[0].size());
        results = DatabaseHelper.split(accounts,1);
        System.assertEquals(8,results.size());
        System.assertEquals(1,results[0].size());
        System.assertEquals(1,results[1].size());
        System.assertEquals(1,results[2].size());
        System.assertEquals(1,results[3].size());
        System.assertEquals(1,results[4].size());
        System.assertEquals(1,results[5].size());
        System.assertEquals(1,results[6].size());
        System.assertEquals(1,results[7].size());
        results = DatabaseHelper.split(accounts,-1);
        System.assertEquals(9,results.size());
        System.assertEquals(0,results[0].size());
        System.assertEquals(1,results[1].size());
        System.assertEquals(1,results[2].size());
        System.assertEquals(1,results[3].size());
        System.assertEquals(1,results[4].size());
        System.assertEquals(1,results[5].size());
        System.assertEquals(1,results[6].size());
        System.assertEquals(1,results[7].size());
        System.assertEquals(1,results[8].size());
        results = DatabaseHelper.split(accounts,4);
        System.assertEquals(2,results.size());
        System.assertEquals(4,results[0].size());
        System.assertEquals(4,results[1].size());
        results = DatabaseHelper.split(accounts,-4);
        System.assertEquals(3,results.size());
        System.assertEquals(0,results[0].size());
        System.assertEquals(4,results[1].size());
        System.assertEquals(4,results[2].size());
    }
}
