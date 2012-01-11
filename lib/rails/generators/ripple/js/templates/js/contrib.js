// -------------------------------------------------------------------
//
// This file contains Javascript MapReduce functions copied from the
// "Riak Function Contrib" project.
//
Riak.Contrib = {
    // Count keys in a group of results.
    // http://contrib.basho.com/count_keys.html
    mapCount: function(){
        return [1];
    },

    // Generate commonly used statistics from an array of numbers.
    // Supports count, sum, min, max, percentiles, mean, variance, and
    // stddev.
    // http://contrib.basho.com/stats.html
    reduceStats: function(data) {
        var result = {};

        data.sort(function(a,b){return a-b;});
        result.count = data.length;

        // Since the data is sorted, the minimum value
        // is at the beginning of the array, the median
        // value is in the middle of the array, and the
        // maximum value is at the end of the array.
        result.min = data[0];
        result.max = data[data.length - 1];

        var ntileFunc = function(percentile){
            if (data.length == 1) return data[0];
            var ntileRank = ((percentile/100) * (data.length - 1)) + 1;
            var integralRank = Math.floor(ntileRank);
            var fractionalRank = ntileRank - integralRank;
            var lowerValue = data[integralRank-1];
            var upperValue = data[integralRank];
            return (fractionalRank * (upperValue - lowerValue)) + lowerValue;
        };

        result.percentile25 = ntileFunc(25);
        result.median = ntileFunc(50);
        result.percentile75 = ntileFunc(75);
        result.percentile99 = ntileFunc(99);

        // Compute the mean and variance using a
        // numerically stable algorithm.
        var sqsum = 0;
        result.mean = data[0];
        result.sum = result.mean * result.count;
        for (var i = 1;  i < data.length;  ++i) {
            var x = data[i];
            var delta = x - result.mean;
            var sweep = i + 1.0;
            result.mean += delta / sweep;
            sqsum += delta * delta * (i / sweep);
            result.sum += x;
        }
        result.variance = sqsum / result.count;
        result.sdev = Math.sqrt(result.variance);

        return result;
    }
};
