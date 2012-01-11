
/*
 * Namespace for Ripple's built-in MapReduce functions.
 */
var Ripple = {
    /*
     * Filter input values by simple equality test on passed "fields"
     * argument. Returns bucket/key pairs for use in later map phases.
     *
     * Raw Phase Example:
     *  {"map":{
     *          "language":"javascript",
     *          "name":"Ripple.filterByFields",
     *          "arg":{"manufactured":true, "name":"widget"}
     *          }}
     *
     * Ruby invocation example:
     *   mr.map("Ripple.filterByFields",
     *          :arg => {:manufactured => true, :name => "widget"})
     *
     */
    filterByFields: function(value, keyData, fields){
        var object = Riak.mapValuesJson(value)[0];
        for(field in fields){
            if(object[field] != fields[field])
                return [];
        }
        return [[value.bucket, value.key]];
    },
    /*
     * Filter input values by various conditions passed as the
     * "conditions" argument. Returns bucket/key pairs for use in
     * later map phases.
     *
     * Valid operators:
     *   ==, eq      (equality)
     *   !=, neq     (inequality)
     *   <, lt       (less than)
     *   =<, <=, lte (less than or equal)
     *   >, gt       (greater than)
     *   >=, =>, gte (greater than or equal)
     *   ~=, match   (regular expression match)
     *   between     (inclusive numeric range)
     *   includes    (String or Array inclusion)
     *
     * Example:
     *   {"map":{
     *           "language":"javascript",
     *           "name":"Ripple.filterByConditions",
     *           "arg":{"tags":{"includes":"riak"}, "title":{"~=":"schema"}}
     *          }}
     *
     * Ruby invocation example:
     *   mr.map("Ripple.filterByConditions",
     *          :arg => {:tags => {:includes => "riak"},
     *                   :title => {"~=" => "schema"}})
     */
    filterByConditions: function(value, keyData, conditions){
        var object = Riak.mapValuesJson(value)[0];
        for(condition in conditions){
            if(!Ripple.conditionMatch(condition, conditions[condition], object))
                return [];
        }
        return [[value.bucket, value.key]];
    },
    /*
     * Given a specific field and test, returns whether the object
     * matches the condition specified by the test. Used internally by
     * Ripple.filterByConditions map phases.
     */
    conditionMatch: function(field, test, object){
        for(t in test){
            switch(t){
            case "==": case "eq":
                if(object[field] != test[t])
                    return false;
                break;
            case "!=": case "neq":
                if(object[field] == test[t])
                    return false;
                break;
            case "<":  case "lt":
                if(object[field] >= test[t])
                    return false;
                break;
            case "=<": case "<=": case "lte":
                if(object[field] > test[t])
                    return false;
                break;
            case ">":  case "gt":
                if(object[field] <= test[t])
                    return false;
                break;
            case ">=": case "=>": case "gte":
                if(object[field] < test[t])
                    return false;
                break;
            case "~=": case "match":
                if(new RegExp(object[field],"i").test(test[t]))
                    return false;
                break;
            case "between": // Inclusive on both ends
                if(object[field] < test[t][0] || object[field] > test[t][1])
                    return false;
                break;
            case "includes": // Only works with String, Array
                if(object[field].indexOf(test[t]) == -1)
                    return false;
                break;
            default:
                ejsLog("Invalid condition for field " + field + ": " + t + " " + test[t], "ripple-error.log");
                break;
            }
        }
        return true;
    },
    /*
     * Returns the mapped object without modification. Useful when
     * preceded by map phases that do filtering or link phases.
     */
    mapIdentity: function(value, kd, arg){
        return [value];
    },
    /*
     * Returns the passed values without modification. Useful as an
     * intermediary before reduce phases that require the entire
     * result set to be present (limits).
     */
    reduceIdentity: function(values, arg){
        return values;
    }
};
