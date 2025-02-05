// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/grpc;
import ballerina/io;

configurable string currencyJsonPath = "./data/currency_conversion.json";

@display {
    label: "",
    id: "currency"
}
@grpc:Descriptor {value: DEMO_DESC}
service "CurrencyService" on new grpc:Listener(9093) {
    final map<decimal> & readonly currencyMap;

    function init() returns error? {
        json currencyJson = check io:fileReadJson(currencyJsonPath);
        self.currencyMap = check parseCurrencyJson(currencyJson).cloneReadOnly();
    }

    remote function GetSupportedCurrencies(Empty request) returns GetSupportedCurrenciesResponse|error {
        return {currency_codes: self.currencyMap.keys()};

    }
    remote function Convert(CurrencyConversionRequest request) returns Money|error {
        Money moneyFrom = request.'from;
        final decimal fractionSize = 1000000000;
        //From Unit
        decimal pennies = <decimal>moneyFrom.nanos / fractionSize;
        decimal totalUSD = <decimal>moneyFrom.units + pennies;

        //UNIT Euro
        decimal rate = self.currencyMap.get(moneyFrom.currency_code);
        decimal euroAmount = totalUSD / rate;

        //UNIT to Target
        decimal targetRate = self.currencyMap.get(request.to_code);
        decimal targetAmount = euroAmount * targetRate;

        int units = <int>targetAmount.floor();
        int nanos = <int>decimal:floor((targetAmount - <decimal>units) * fractionSize);

        return {
            currency_code: request.to_code,
            nanos,
            units
        };
    }
}

isolated function parseCurrencyJson(json jsonContents) returns map<decimal>|error {
    map<decimal> currencies = {};
    map<string> originalValues = check jsonContents.cloneWithType();

    foreach string key in originalValues.keys() {
        string value = originalValues.get(key);
        currencies[key] = check decimal:fromString(value);
    }
    return currencies;
}
