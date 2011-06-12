Installing bitcoin-mining-proxy
===============================

Setting up the database
-----------------------

This particlar fork of bitcoin-mining-proxy has been beaten and whipped a little bit until it works on top of postgresql.  Use at your own risk, I (mloftis at github, mloftis@wgops.com ) have only done enough work to make it go.  There quite possibly are bugs in this fork.  I get python traceback errors occasionally from phoenix (1.48) when using my fork, I do not know if those problems exist in the parent fork since I never tried it!

Some minor changes for PgSQL, there was one place where deletion wouldn't work, I also reduced all delete/join stuff to simple deletes, I've set the foreign keys to just default (restrict) on cascade right now until I get a better sense of whats going on with this software.

1.  Create a PostGreSQL user for the proxy.
2.  Create a database for the proxy, possibly setting the default owner to the user above.  You should create the database with UTF8 encoding -- `createdb -e UTF8 poolproxy` -- you may have to specify the template0 database in order to do this depending on your installations default encoding!
Perform the following steps to set up the database:
3.  Import the schema file at `database/schema-pg.sql` as the owner of the database.

Everything else here should apply.  Note that instead of storing hex characters in the database, I store the binary valueas as bytea, I also log the submitted data entirely, and any error code coming back from the upstream pool.  TODO - make the UI display this information.

Configuring the proxy
---------------------

1.  Copy `htdocs/config.inc.php.sample` to `htdocs/config.inc.php`.
2.  Overwrite the sample database information with your real database information.
3.  Set the admin user and password.  This will be used when logging in to the web management console.
4.  Set the site URI; this is the URI the mining proxy will be reachable from.  If you install directly into your web root, the default value `'/'` is correct.

Setting up the web server
-------------------------

bitcoin-mining-proxy only requires a web server that can run PHP scripts.  Just point your web root at the htdocs folder and everything should be all set.

These scripts require that the `magic_quotes_gpc` PHP flag be disabled.  The included `.htaccess` file will take care of this automatically if your configuration allows PHP flags to be changed from `.htaccess` files.

Note that while you can install to a subdirectory, some miners do not support this!  These miners only accept a host and port, but not a path.  You will have to use htdocs as the web root in order for these miners to work.

Setting up the proxy
--------------------

Navigate your browser to the admin directory inside the htdocs folder.  So if you installed at `http://www.example.com/` then you would go to `http://www.example.com/admin/`.  You will be asked to authenticate; enter the admin credentials you put in `htdocs/config.inc.php`.

The first thing you will want to do is add all the pools you will be using.  Click the "pools" link and then the "new pool" button.  Enter a name for the pool (this is for display purposes only) and the pool's URL.  **Do not** enter login credentials as part of the URL; pool credentials are managed elsewhere.  So to use luke-jr's pool, for example, you would enter `http://pool.bitcoin.dashjr.org:8337`, omitting your Bitcoin address.  Check the enabled checkbox and save the pool.  Repeat this for all the other pools you will be using.

Now set up some worker accounts.  You should use a different worker account for each instance of mining software you are running.  This will allow you to remotely administrate their pool assignments separately, as well as determine which miners are not operating correctly.  If you used one account for several workers, they would be treated as one distinct miner by the proxy and information about them will be aggregated, and usually you don't want that.

Once you have all your worker accounts set up, you need to associate workers with the pools you want them to work on.  Click the "manage pools" button next to a worker.  You will see a list of all your pools; each will have a "create pool assignment" button.  After clicking it, you will be asked for details about the assignment:

* **Priority:** This field is used to order the pool assignemnts.  If you have multiple enabled assignments for a worker, the one with the highest priority will be tried first.  If it is unreachable or returns an error, the assignment with the next-highest priority will be tried, and so on.  If all pools cannot be queried for work, an error will be returned to the worker.  If two assignments have the same priority, the order in which they will be tried is undefined.
* **Enabled:** Check this box to enable the assignment.  If an assignment is not enabled, the proxy will skip that pool when the worker asks for work.
* **Pool username/password:** The worker's authentication information for the pool.  If you are mining on a pool that requires or supports different worker accounts for each worker (like slush's pool and deepbit) you can enter different information here.  If all the workers will share credentials, you will have to enter the credentials for each assignment.

You do not have to assign each worker to every pool if you don't want to.  Unassigned pools will simply be ignored.

At this point you should be able to point your workers at the proxy and they will start working.  You can verify this by watching the "Worker status" section on the dashboard.

Quick pool toggling
-------------------

In the pool list you will see a red or green flag for each pool indicating whether it is enabled.  You can click the flag to quickly toggle the status of the pool.  This will globally disable the pool for all workers.  Disabled pools will have a red background.

In the pool assignment list for specific workers, there are two flags; one for the pool and one for the specific assignment.  You can click the flag for the assignment to quickly toggle the assignment on or off.  This will affect only the worker you are managing.  You cannot click the pool's flag.  This is to prevent a pool from being accidentally disabled globally.  Rows with a red background indicate that the worker will not request work from this pool -- in other words, if either the pool or the assignment are disabled.

Note that disabling a pool or assignment will not prevent any shares from being submitted if the worker is currently working that pool.  It will affect new work requests only.  So you can safely disable a pool while your miners are running and they will finish their current work, switching over to the next pool in the list on their next getwork request.

Long polling support
--------------------

bitcoin-mining-proxy supports long polling servers.  It will rewrite any long polling URL received from a pool so that the long polling request passes through the proxy.

There is one caveat: if the pool is disabled while a worker has an outstanding long poll request, it may not notice this, depending on the logic in the client!  This means that the client will effectively be working without long polling against its new pool until its outstanding request returns.  At that point it may begin working on the work returned in the long poll request, which will be for the disabled pool!  This is ok; the work submissions will be correctly routed back to the now-disabled pool.

This problem may be fixed in a future release by having the long-polling code check the database every few seconds to make sure that the pool and assignment it is proxying for are still enabled, returning early with an error code if it finds either to be disabled.

Database maintenance
--------------------

You should not have to do very much to maintain the database, but you may need to delete some data occasionally.  The `work_data` table is likely to grow quite large if left alone.  Depending on how many miners you are running and what their request rate is, you may need to clean out this table as often as once a week.  You can use the following query to do so:

    DELETE FROM `work_data` WHERE DATEDIFF(UTC_TIMESTAMP(), `time_requested`) > 0

Note that this will cause some stats to disappear; for example, if one of your workers has not been operating since midnight UTC, it will show as never having requested work on the dashboard.  Do not simply truncate the table; if you do this while your miners are working, the proxy will be unable to route share submissions back to their correct pool.

If the submitted_work table is growing too large, you can execute a similar query to clean it out:

    DELETE FROM `submitted_work` WHERE DATEDIFF(UTC_TIMESTAMP(), `time`) > 7

You may truncate this table if you wish since the miners do not depend on it to request work.  It is an informational table only.  However, keeping a week or two's worth of data around is a good idea in case you need to report a statistical discrepancy to a pool operator.  It's always good to have logs.

The proxy may at some point be able to purge old data periodically by itself.  In the meantime, you will have to do so manually.

Upgrading
---------
When upgrading the proxy software, make sure to inspect any changes to `htdocs/config.inc.php.sample` and apply them (with customizations) as needed to your local configuration.  Failure to do this might result in errant behavior.
