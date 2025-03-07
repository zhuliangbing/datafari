/*******************************************************************************
 *  * Copyright 2020 France Labs
 *  *
 *  * Licensed under the Apache License, Version 2.0 (the "License");
 *  * you may not use this file except in compliance with the License.
 *  * You may obtain a copy of the License at
 *  *
 *  *      http://www.apache.org/licenses/LICENSE-2.0
 *  *
 *  * Unless required by applicable law or agreed to in writing, software
 *  * distributed under the License is distributed on an "AS IS" BASIS,
 *  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  * See the License for the specific language governing permissions and
 *  * limitations under the License.
 *******************************************************************************/
package com.francelabs.datafari.rest.v1_0.users;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import javax.servlet.http.HttpServletRequest;

import com.francelabs.datafari.audit.AuditLogUtil;
import com.francelabs.datafari.exception.DatafariServerException;
import com.francelabs.datafari.rest.v1_0.exceptions.BadRequestException;
import com.francelabs.datafari.rest.v1_0.exceptions.DataNotFoundException;
import com.francelabs.datafari.rest.v1_0.exceptions.InternalErrorException;
import com.francelabs.datafari.rest.v1_0.exceptions.NotAuthenticatedException;
import com.francelabs.datafari.rest.v1_0.utils.RestAPIUtils;
import com.francelabs.datafari.service.db.UserHistoryDataService;
import com.francelabs.datafari.user.Lang;
import com.francelabs.datafari.user.UiConfig;
import com.francelabs.datafari.utils.AuthenticatedUserName;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class Users {

    private static final Logger logger = LogManager.getLogger(Users.class.getName());

    protected JSONObject getUiConfigFromDB(String authenticatedUserName, HttpServletRequest request) {
        final JSONParser parser = new JSONParser();
        try {
            String uiConfig = UiConfig.getUiConfig(authenticatedUserName);
            JSONObject uiConfigObj = new JSONObject();
            if (uiConfig != null) {
                try {
                    uiConfigObj = (JSONObject) parser.parse(uiConfig);
                } catch (ParseException e) {
                    logger.warn("Couldn't parse the ui config extracted from Cassandra for a user.");
                }
            }
            AuditLogUtil.log("cassandra", authenticatedUserName, request.getRemoteAddr(),
                    "Accessed saved ui config for user " + authenticatedUserName);
            return uiConfigObj;
        } catch (DatafariServerException e) {
            logger.error("Database conenction error while retrieving user ui config.");
            throw new InternalErrorException("Database conenction error while retrieving user ui config.");
        }
    }

    protected void saveUiConfigToDB(String authenticatedUserName, JSONObject body, HttpServletRequest request)
            throws DatafariServerException {
        JSONObject bodyUiConfig = (JSONObject) body.get("uiConfig");
        if (bodyUiConfig != null) {
            UiConfig.setUiConfig(authenticatedUserName, bodyUiConfig.toJSONString());
            AuditLogUtil.log("cassandra", "system", request.getRemoteAddr(),
                    "Modified saved ui config for user " + authenticatedUserName);
        }
    }

    protected JSONObject getUserInfoFromDB(final String authenticatedUserName, final HttpServletRequest request) {
        HashMap<String, Object> responseContent = new HashMap<>();
        if (authenticatedUserName != null) {
            responseContent.put("name", authenticatedUserName);
            ArrayList<String> roles = new ArrayList<>();
            if (request.isUserInRole("SearchAdministrator")) {
                roles.add("SearchAdministrator");
            }
            if (request.isUserInRole("SearchExpert")) {
                roles.add("SearchExpert");
            }
            responseContent.put("roles", roles);
            try {
                String lang = Lang.getLang(authenticatedUserName);
                AuditLogUtil.log("cassandra", authenticatedUserName, request.getRemoteAddr(),
                        "Accessed saved language for user " + authenticatedUserName);
                responseContent.put("lang", lang);
            } catch (DatafariServerException e) {
                logger.error("Database conenction error while retrieving user language.");
                throw new InternalErrorException("Database conenction error while retrieving user language.");
            }
            JSONObject uiConfigObj = getUiConfigFromDB(authenticatedUserName, request);
            responseContent.put("uiConfig", uiConfigObj);
            return new JSONObject(responseContent);
        } else {
            throw new DataNotFoundException("No user currently connected.");
        }
    }

    @GetMapping(value = "/rest/v1.0/users/current", produces = "application/json;charset=UTF-8")
    protected String getUser(final HttpServletRequest request) {
        final String authenticatedUserName = AuthenticatedUserName.getName(request);
        JSONObject responseContent = getUserInfoFromDB(authenticatedUserName, request);
        return RestAPIUtils.buildOKResponse(responseContent);
    }

    @PutMapping(value = "rest/v1.0/users/current", produces = "application/json;charset=UTF-8")
    protected String modifyUser(final HttpServletRequest request, @RequestBody String jsonParam) {
        final JSONParser parser = new JSONParser();
        final String authenticatedUserName = AuthenticatedUserName.getName(request);
        if (authenticatedUserName != null) {
            try {
                final JSONObject body = (JSONObject) parser.parse(jsonParam);
                String bodyLang = (String) body.get("lang");
                if (bodyLang != null) {
                    Lang.setLang(authenticatedUserName, bodyLang);
                    AuditLogUtil.log("cassandra", "system", request.getRemoteAddr(),
                            "Initialized saved language for user " + authenticatedUserName);
                }
                saveUiConfigToDB(authenticatedUserName, body, request);
                JSONObject responseContent = getUserInfoFromDB(authenticatedUserName, request);
                return RestAPIUtils.buildOKResponse(responseContent);
            } catch (ParseException e1) {
                throw new BadRequestException("Couldn't parse the JSON body");
            } catch (DatafariServerException e) {
                logger.error("Error while saving the new lang.");
                throw new InternalErrorException("Error while saving the new lang.");
            }
        } else {
            throw new NotAuthenticatedException("User must be authenticated to perform this action.");
        }
    }

    @GetMapping(value = "rest/v1.0/users/current/history", produces = "application/json;charset=UTF-8")
    protected String getUserHistory(final HttpServletRequest request) {
        final String authenticatedUserName = AuthenticatedUserName.getName(request);
        if (authenticatedUserName != null) {
            HashMap<String, Object> responseContent = new HashMap<>();
            List<String> history;
            try {
                history = UserHistoryDataService.getInstance().getHistory(authenticatedUserName);
                responseContent.put("history", history);
                AuditLogUtil.log("cassandra", "system", request.getRemoteAddr(),
                    "User " + authenticatedUserName + " accessed his request history");
            } catch (DatafariServerException e) {
                logger.error("Error while retrieving the history for a user.");
                throw new InternalErrorException("Error while retrieving the history.");
            }
            return RestAPIUtils.buildOKResponse(new JSONObject(responseContent));
        } else {
            throw new NotAuthenticatedException("User must be authenticated to perform this action.");
        }
    }

    @GetMapping(value = "rest/v1.0/users/current/uiconfig", produces = "application/json;charset=UTF-8")
    protected String getUserUiConfig(final HttpServletRequest request) {
        final String authenticatedUserName = AuthenticatedUserName.getName(request);
        HashMap<String, Object> responseContent = new HashMap<>();
        if (authenticatedUserName != null) {
            JSONObject uiConfigObj = getUiConfigFromDB(authenticatedUserName, request);
            responseContent.put("uiConfig", uiConfigObj);
            return RestAPIUtils.buildOKResponse(new JSONObject(responseContent));
        } else {
            throw new DataNotFoundException("No user currently connected.");
        }
    }

    @PutMapping(value = "rest/v1.0/users/current/uiconfig", produces = "application/json;charset=UTF-8")
    protected String setUserUiConfig(final HttpServletRequest request, @RequestBody String jsonParam) {
        final JSONParser parser = new JSONParser();
        final String authenticatedUserName = AuthenticatedUserName.getName(request);
        if (authenticatedUserName != null) {
            try {
                final JSONObject body = (JSONObject) parser.parse(jsonParam);
                saveUiConfigToDB(authenticatedUserName, body, request);
                return RestAPIUtils.buildOKResponse(body);
            } catch (ParseException e1) {
                throw new BadRequestException("Couldn't parse the JSON body");
            } catch (DatafariServerException e) {
                logger.error("Error while saving the new ui config.");
                throw new InternalErrorException("Error while saving the new ui config.");
            }
        } else {
            throw new NotAuthenticatedException("User must be authenticated to perform this action.");
        }
    }
}