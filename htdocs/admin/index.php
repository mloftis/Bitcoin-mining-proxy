<?php

/*
 * ./htdocs/admin/index.php
 *
 * Copyright (C) 2011  Chris Howie <me@chrishowie.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

require_once(dirname(__FILE__) . '/../common.inc.php');
require_once(dirname(__FILE__) . '/../admin/controller.inc.php');
require_once(dirname(__FILE__) . '/../views/admin/dashboard.view.php');

class AdminDashboardController extends AdminController
{
    public function indexDefaultView()
    {
        global $BTC_PROXY;

        $viewdata = array();

        $pdo = db_connect();

        $viewdata['recent-submissions'] = db_query($pdo, '
            SELECT
                w.name AS worker,
                p.name AS pool,
                sw.result AS result,
                sw.time AS time,
                sw.retries AS retries

            FROM (
                SELECT pool_id, worker_id, result, time, retries

                FROM submitted_work

                ORDER BY time DESC

                LIMIT 10
            ) sw

            INNER JOIN pool p
            ON p.id = sw.pool_id

            INNER JOIN worker w
            ON w.id = sw.worker_id
            ORDER BY time DESC
        ');

        $viewdata['recent-failed-submissions'] = db_query($pdo, '
            SELECT
                w.name AS worker,
                p.name AS pool,
                sw.result AS result,
                sw.time AS time

            FROM (
                SELECT pool_id, worker_id, result, time

                FROM submitted_work

                WHERE result = false

                ORDER BY id DESC

                LIMIT 10
            ) sw

            INNER JOIN pool p
            ON p.id = sw.pool_id

            INNER JOIN worker w
            ON w.id = sw.worker_id
            ORDER BY time DESC
        ');

        $viewdata['worker-status'] = db_query($pdo, '
            SELECT
                w.name AS worker,
                w.id AS worker_id,

                worked.pool_name AS active_pool,
                worked.latest AS active_time,

                submitted.pool_name AS last_accepted_pool,
                submitted.latest AS last_accepted_time,

                sli.shares_last_interval AS shares_last_interval,
                sli.shares_last_interval * 4294967296 / :average_interval / 1000000 as mhash

            FROM worker w

            LEFT OUTER JOIN (
                SELECT
                    wd.worker_id AS worker_id,
                    wd.time_requested AS latest,
                    p.name AS pool_name

                FROM work_data wd

                INNER JOIN (
                    SELECT
                        worker_id,
                        MAX(time_requested) AS latest

                    FROM work_data

                    GROUP BY worker_id
                ) wd2
                    ON wd.worker_id = wd2.worker_id
                   AND wd.time_requested = wd2.latest

                INNER JOIN pool p
                    ON p.id = wd.pool_id

                GROUP BY wd.worker_id, wd.time_requested, p.name
            ) worked

            ON worked.worker_id = w.id

            LEFT OUTER JOIN (
                SELECT
                    sw.worker_id AS worker_id,
                    sw.time AS latest,
                    p.name AS pool_name

                FROM submitted_work sw

                INNER JOIN (
                    SELECT
                        worker_id,
                        MAX(time) AS latest

                    FROM submitted_work

                    WHERE result = true

                    GROUP BY worker_id
                ) sw2
                    ON sw.worker_id = sw2.worker_id
                   AND sw.result = true
                   AND sw.time = sw2.latest

                INNER JOIN pool p
                    ON p.id = sw.pool_id

                GROUP BY sw.worker_id,sw.time,p.name
            ) submitted

            ON submitted.worker_id = w.id

            LEFT OUTER JOIN (
                SELECT
                    worker_id,
                    COUNT(result) AS shares_last_interval
                FROM
                    submitted_work sw
                WHERE
                    time >= NOW() - \''.(int)$BTC_PROXY['average_interval'].'\'::INTERVAL
                GROUP BY
                    sw.worker_id
            ) sli
            ON sli.worker_id = w.id

            ORDER BY w.name
        ', array(
            ':average_interval'     => $BTC_PROXY['average_interval']
        ));

        return new AdminDashboardView($viewdata);
    }
}

MvcEngine::run(new AdminDashboardController());

?>
