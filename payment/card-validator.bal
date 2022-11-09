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

import ballerina/regex;
import ballerina/time;

type CardValidationError error;

type CardCompany record {|
    string name;
    string pattern;
|};

class CardValidator {
    final CardCompany[] companies = [
        {
            name: "VISA",
            pattern: "^4[0-9]{12}(?:[0-9]{3})?$"
        },
        {
            name: "MASTERCARD",
            pattern: "^5[1-5][0-9]{14}$"

        }
    ];
    final string card;
    final int expireYear;
    final int expireMonth;

    isolated function init(string card, int expireYear, int expireMonth) {
        self.card = regex:replaceAll(card, "[^0-9]+", "");
        self.expireYear = expireYear;
        self.expireMonth = expireMonth;
    }

    isolated function isValid() returns CardCompany|error {
        if (self.card.length() < 13) || (self.card.length() > 19) {
            return error CardValidationError("failed length check");
        }

        if !check self.isLuhnValid() {
            return error CardValidationError("failed luhn check");
        }

        CardCompany? gleanCompany = self.getCompany();
        if gleanCompany is () {
            return error CardValidationError("unsupported card company");
        }

        if self.isExpired() {
            return error CardValidationError("card expired");
        }

        return gleanCompany;
    }

    isolated function isLuhnValid() returns boolean|error {
        int digits = self.card.length();
        int oddOrEven = digits & 1;
        int sum = 0;

        foreach int count in 0 ..< digits {
            int digit = 0;
            digit = check int:fromString(self.card[count]);

            if ((count & 1) ^ oddOrEven) == 0 {
                digit *= 2;
                if digit > 9 {
                    digit -= 9;
                }
            }
            sum += digit;
        }
        return sum != 0 && (sum % 10 == 0);
    }

    isolated function getCompany() returns CardCompany|() {
        foreach CardCompany company in self.companies {
            if regex:matches(self.card, company.pattern) {
                return company;
            }
        }
        return ();
    }

    isolated function isExpired() returns boolean {
        int expireYear = self.expireYear;
        int expireMonth = self.expireMonth;

        time:Civil currentTime = time:utcToCivil(time:utcNow());
        int month = currentTime.month;
        int year = currentTime.year;

        if year > expireYear {
            return true;
        }
        
        return year == expireYear && month > expireMonth;
    }
}
