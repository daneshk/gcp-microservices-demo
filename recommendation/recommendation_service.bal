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
import ballerina/log;

configurable string catalogHost = "localhost";

@display {
    label: "",
    id: "recommendation"
}
@grpc:Descriptor {value: DEMO_DESC}
service "RecommendationService" on new grpc:Listener(9090) {
    @display {
        label: "",
        id: "catalog"
    }
    final ProductCatalogServiceClient catalogClient;

    function init() returns error? {
        self.catalogClient = check new (string `http://${catalogHost}:9091`);
    }

    isolated remote function ListRecommendations(ListRecommendationsRequest request) returns ListRecommendationsResponse|error {
        ListProductsResponse|grpc:Error listProducts = self.catalogClient->ListProducts({});
        if listProducts is grpc:Error {
            log:printError("failed to call ListProducts of catalog service", 'error = listProducts);
            return error grpc:InternalError("failed to get list of products from catalog service", listProducts);
        }

        return {
            product_ids: from Product product in listProducts.products
                where request.product_ids.indexOf(product.id) is ()
                limit 5
                select product.id
        };
    }
}
