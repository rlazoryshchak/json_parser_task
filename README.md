# Problem: Bitcoin Time Series Filtering and Grouping
Please use either Ruby language to implement a method
(function) or a class that will parse this json data and return an array with the
following structure:
```
[[date, price], [date, price], ...]
```
Records should be in descending order by default. Input parameters should be:
 - `order_dir` - desc, asc (desc by default) to order by date
 - `filter_date_from` - date string or date object, if passed, list should be filtered by this date as a start date
 - `filter_date_to` - date string or date object, if passed, list should be filtered by this date as an end date
 - `granularity` - daily (default), weekly, monthly, quarterly. This parameter should group price data by the given period. Based on granularity, date should be the first day of week, month, etc. Price in each group should be calculated as average value. For example, if granularity is weekly - price should be calculated as `price_sum_for_week / 7`.
 
Please also implement unit tests using Rspec framework.

### Link to Json Data
https://pkgstore.datahub.io/cryptocurrency/bitcoin/bitcoin_json/data/3d47ebaea5707774cb076c9cd2e0ce8c/bitcoin_json.json

