/* $Id$ */

/**
* Licensed to the Apache Software Foundation (ASF) under one or more
* contributor license agreements. See the NOTICE file distributed with
* this work for additional information regarding copyright ownership.
* The ASF licenses this file to You under the Apache License, Version 2.0
* (the "License"); you may not use this file except in compliance with
* the License. You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/
package com.francelabs.datafari.transformation.metadatacleaner;

import java.io.File;
import java.io.IOException;
import java.io.Reader;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;

import org.apache.manifoldcf.agents.interfaces.IOutputAddActivity;
import org.apache.manifoldcf.agents.interfaces.IOutputCheckActivity;
import org.apache.manifoldcf.agents.interfaces.RepositoryDocument;
import org.apache.manifoldcf.agents.interfaces.ServiceInterruption;
import org.apache.manifoldcf.agents.system.Logging;
import org.apache.manifoldcf.core.interfaces.ConfigParams;
import org.apache.manifoldcf.core.interfaces.IHTTPOutput;
import org.apache.manifoldcf.core.interfaces.IPostParameters;
import org.apache.manifoldcf.core.interfaces.IThreadContext;
import org.apache.manifoldcf.core.interfaces.ManifoldCFException;
import org.apache.manifoldcf.core.interfaces.Specification;
import org.apache.manifoldcf.core.interfaces.SpecificationNode;
import org.apache.manifoldcf.core.interfaces.VersionContext;

import com.francelabs.datafari.annotator.exception.RegexException;

/**
 * This connector works as a transformation connector, but does nothing other than logging.
 *
 */
public class MetadataCleaner extends org.apache.manifoldcf.agents.transformation.BaseTransformationConnector {
  public static final String _rcsid = "@(#)$Id$";

  private static final String EDIT_SPECIFICATION_JS = "editSpecification.js";
  private static final String EDIT_SPECIFICATION_METADATA_CLEANER_HTML = "editSpecification_MetadataCleaner.html";
  private static final String VIEW_SPECIFICATION_HTML = "viewSpecification.html";

  protected static final String ACTIVITY_CLEAN = "clean";

  protected static final String[] activitiesList = new String[] { ACTIVITY_CLEAN };

  /**
   * Connect.
   *
   * @param configParameters is the set of configuration parameters, which in this case describe the root directory.
   */
  @Override
  public void connect(final ConfigParams configParameters) {
    super.connect(configParameters);
  }

  /**
   * Close the connection. Call this before discarding the repository connector.
   */
  @Override
  public void disconnect() throws ManifoldCFException {
    super.disconnect();
  }

  /**
   * This method is periodically called for all connectors that are connected but not in active use.
   */
  @Override
  public void poll() throws ManifoldCFException {

  }

  /**
   * This method is called to assess whether to count this connector instance should actually be counted as being connected.
   *
   * @return true if the connector instance is actually connected.
   */
  @Override
  public boolean isConnected() {
    return true;
  }

  /**
   * Return a list of activities that this connector generates. The connector does NOT need to be connected before this method is called.
   *
   * @return the set of activities.
   */
  @Override
  public String[] getActivitiesList() {
    return activitiesList;
  }

  /**
   * Output the configuration header section. This method is called in the head section of the connector's configuration page. Its purpose is to add the required tabs to the list, and to output any
   * javascript methods that might be needed by the configuration editing HTML.
   *
   * @param threadContext is the local thread context.
   * @param out           is the output to which any HTML should be sent.
   * @param parameters    are the configuration parameters, as they currently exist, for this connection being configured.
   * @param tabsArray     is an array of tab names. Add to this array any tab names that are specific to the connector.
   */
  @Override
  public void outputConfigurationHeader(final IThreadContext threadContext, final IHTTPOutput out, final Locale locale, final ConfigParams parameters, final List<String> tabsArray)
      throws ManifoldCFException, IOException {

  }

  /**
   * Output the configuration body section. This method is called in the body section of the connector's configuration page. Its purpose is to present the required form elements for editing. The coder
   * can presume that the HTML that is output from this configuration will be within appropriate <html>, <body>, and <form> tags. The name of the form is "editconnection".
   *
   * @param threadContext is the local thread context.
   * @param out           is the output to which any HTML should be sent.
   * @param parameters    are the configuration parameters, as they currently exist, for this connection being configured.
   * @param tabName       is the current tab name.
   */
  @Override
  public void outputConfigurationBody(final IThreadContext threadContext, final IHTTPOutput out, final Locale locale, final ConfigParams parameters, final String tabName)
      throws ManifoldCFException, IOException {

  }

  /**
   * Process a configuration post. This method is called at the start of the connector's configuration page, whenever there is a possibility that form data for a connection has been posted. Its
   * purpose is to gather form information and modify the configuration parameters accordingly. The name of the posted form is "editconnection".
   *
   * @param threadContext   is the local thread context.
   * @param variableContext is the set of variables available from the post, including binary file post information.
   * @param parameters      are the configuration parameters, as they currently exist, for this connection being configured.
   * @return null if all is well, or a string error message if there is an error that should prevent saving of the connection (and cause a redirection to an error page).
   */
  @Override
  public String processConfigurationPost(final IThreadContext threadContext, final IPostParameters variableContext, final Locale locale, final ConfigParams parameters) throws ManifoldCFException {
    return null;
  }

  /**
   * View configuration. This method is called in the body section of the connector's view configuration page. Its purpose is to present the connection information to the user. The coder can presume
   * that the HTML that is output from this configuration will be within appropriate <html> and <body> tags.
   *
   * @param threadContext is the local thread context.
   * @param out           is the output to which any HTML should be sent.
   * @param parameters    are the configuration parameters, as they currently exist, for this connection being configured.
   */
  @Override
  public void viewConfiguration(final IThreadContext threadContext, final IHTTPOutput out, final Locale locale, final ConfigParams parameters) throws ManifoldCFException, IOException {

  }

  /**
   * Get an output version string, given an output specification. The output version string is used to uniquely describe the pertinent details of the output specification and the configuration, to
   * allow the Connector Framework to determine whether a document will need to be output again. Note that the contents of the document cannot be considered by this method, and that a different
   * version string (defined in IRepositoryConnector) is used to describe the version of the actual document.
   *
   * This method presumes that the connector object has been configured, and it is thus able to communicate with the output data store should that be necessary.
   *
   * @param os is the current output specification for the job that is doing the crawling.
   * @return a string, of unlimited length, which uniquely describes output configuration and specification in such a way that if two such strings are equal, the document will not need to be sent
   *         again to the output data store.
   */
  @Override
  public VersionContext getPipelineDescription(final Specification os) throws ManifoldCFException, ServiceInterruption {
    final SpecPacker sp = new SpecPacker(os);
    return new VersionContext(sp.toPackedString(), params, os);
  }

  // We intercept checks pertaining to the document format and send modified
  // checks further down

  /**
   * Detect if a mime type is acceptable or not. This method is used to determine whether it makes sense to fetch a document in the first place.
   *
   * @param pipelineDescription is the document's pipeline version string, for this connection.
   * @param mimeType            is the mime type of the document.
   * @param checkActivity       is an object including the activities that can be performed by this method.
   * @return true if the mime type can be accepted by this connector.
   */
  @Override
  public boolean checkMimeTypeIndexable(final VersionContext pipelineDescription, final String mimeType, final IOutputCheckActivity checkActivity) throws ManifoldCFException, ServiceInterruption {
    return true;
  }

  /**
   * Pre-determine whether a document (passed here as a File object) is acceptable or not. This method is used to determine whether a document needs to be actually transferred. This hook is provided
   * mainly to support search engines that only handle a small set of accepted file types.
   *
   * @param pipelineDescription is the document's pipeline version string, for this connection.
   * @param localFile           is the local file to check.
   * @param checkActivity       is an object including the activities that can be done by this method.
   * @return true if the file is acceptable, false if not.
   */
  @Override
  public boolean checkDocumentIndexable(final VersionContext pipelineDescription, final File localFile, final IOutputCheckActivity checkActivity) throws ManifoldCFException, ServiceInterruption {
    // Document contents are not germane anymore, unless it looks like Tika
    // won't accept them.
    // Not sure how to check that...
    return true;
  }

  /**
   * Pre-determine whether a document's length is acceptable. This method is used to determine whether to fetch a document in the first place.
   *
   * @param pipelineDescription is the document's pipeline version string, for this connection.
   * @param length              is the length of the document.
   * @param checkActivity       is an object including the activities that can be done by this method.
   * @return true if the file is acceptable, false if not.
   */
  @Override
  public boolean checkLengthIndexable(final VersionContext pipelineDescription, final long length, final IOutputCheckActivity checkActivity) throws ManifoldCFException, ServiceInterruption {
    // Always true
    return true;
  }

  /**
   * Add (or replace) a document in the output data store using the connector. This method presumes that the connector object has been configured, and it is thus able to communicate with the output
   * data store should that be necessary. The OutputSpecification is *not* provided to this method, because the goal is consistency, and if output is done it must be consistent with the output
   * description, since that was what was partly used to determine if output should be taking place. So it may be necessary for this method to decode an output description string in order to determine
   * what should be done.
   *
   * @param documentURI         is the URI of the document. The URI is presumed to be the unique identifier which the output data store will use to process and serve the document. This URI is
   *                            constructed by the repository connector which fetches the document, and is thus universal across all output connectors.
   * @param outputDescription   is the description string that was constructed for this document by the getOutputDescription() method.
   * @param document            is the document data to be processed (handed to the output data store).
   * @param authorityNameString is the name of the authority responsible for authorizing any access tokens passed in with the repository document. May be null.
   * @param activities          is the handle to an object that the implementer of a pipeline connector may use to perform operations, such as logging processing activity, or sending a modified
   *                            document to the next stage in the pipeline.
   * @return the document status (accepted or permanently rejected).
   * @throws IOException only if there's a stream error reading the document data.
   */
  @Override
  public int addOrReplaceDocumentWithException(final String documentURI, final VersionContext pipelineDescription, final RepositoryDocument document, final String authorityNameString,
      final IOutputAddActivity activities) throws ManifoldCFException, ServiceInterruption, IOException {

    final SpecPacker spec = new SpecPacker(pipelineDescription.getSpecification());

    final Iterator<String> fieldsI = document.getFields();
    // As we will replace the metadata with the "cleaned" ones, we need to store them in a separate hashmap
    final Map<String, Object[]> cleanMetadata = new HashMap<>();
    try {
      // Iterate over all the metadata, delete them and store their cleaned names and values in the cleanMetadata hashmap we just created
      while (fieldsI.hasNext()) {
        final String fieldName = fieldsI.next();
        String cleanFieldName = fieldName;
        for (final String nameRegex : spec.nameCleaners.keySet()) {
          cleanFieldName = fieldName.replaceAll(nameRegex, spec.nameCleaners.get(nameRegex));
        }
        final Object[] fieldValues = document.getField(fieldName);
        if (fieldValues instanceof String[]) {
          for (final String valueRegex : spec.valueCleaners.keySet()) {
            for (int i = 0; i < fieldValues.length; i++) {
              final String cleanValue = fieldValues[i].toString().replaceAll(valueRegex, spec.valueCleaners.get(valueRegex));
              fieldValues[i] = cleanValue;
            }
          }
        }
        // Remove the current metadata
        fieldsI.remove();
        // Store its "cleaned" equivalent
        cleanMetadata.put(cleanFieldName, fieldValues);

      }

      // Insert again the metadata with their "cleaned" equivalent
      for (final String cleanFieldName : cleanMetadata.keySet()) {
        final Object[] cleanValues = cleanMetadata.get(cleanFieldName);
        if (cleanValues instanceof String[]) {
          document.addField(cleanFieldName, (String[]) cleanValues);
        } else if (cleanValues instanceof Date[]) {
          document.addField(cleanFieldName, (Date[]) cleanValues);
        } else if (cleanValues instanceof Reader[]) {
          document.addField(cleanFieldName, (Reader[]) cleanValues);
        }
      }
      activities.recordActivity(null, ACTIVITY_CLEAN, null, documentURI, "OK", "");
    } catch (final Exception e) {
      activities.recordActivity(null, ACTIVITY_CLEAN, null, documentURI, "KO", e.getMessage());
      Logging.ingest.error("Unable to clean document " + documentURI, e);
    }

    return activities.sendDocument(documentURI, document);

  }

  /**
   * Obtain the name of the form check javascript method to call.
   *
   * @param connectionSequenceNumber is the unique number of this connection within the job.
   * @return the name of the form check javascript method.
   */
  @Override
  public String getFormCheckJavascriptMethodName(final int connectionSequenceNumber) {
    return "s" + connectionSequenceNumber + "_checkSpecification";
  }

  /**
   * Obtain the name of the form presave check javascript method to call.
   *
   * @param connectionSequenceNumber is the unique number of this connection within the job.
   * @return the name of the form presave check javascript method.
   */
  @Override
  public String getFormPresaveCheckJavascriptMethodName(final int connectionSequenceNumber) {
    return "s" + connectionSequenceNumber + "_checkSpecificationForSave";
  }

  protected static void fillInMetadataCleanerSpecification(final Map<String, Object> paramMap, final Specification os) {

    final Map<String, String> nameCleaners = new HashMap<>();
    final Map<String, String> valueCleaners = new HashMap<>();

    for (int i = 0; i < os.getChildCount(); i++) {
      final SpecificationNode sn = os.getChild(i);

      if (sn.getType().equals(MetadataCleanerConfig.NODE_NAMECLEANER)) {
        final String nameCleanerRegex = sn.getAttributeValue(MetadataCleanerConfig.ATTRIBUTE_REGEX);
        final String nameCleanerValue = sn.getAttributeValue(MetadataCleanerConfig.ATTRIBUTE_VALUE);
        if (nameCleanerRegex != null) {
          nameCleaners.put(nameCleanerRegex, nameCleanerValue);
        }
      } else if (sn.getType().equals(MetadataCleanerConfig.NODE_VALUECLEANER)) {
        final String valueCleanerRegex = sn.getAttributeValue(MetadataCleanerConfig.ATTRIBUTE_REGEX);
        final String valueCleanerValue = sn.getAttributeValue(MetadataCleanerConfig.ATTRIBUTE_VALUE);
        if (valueCleanerRegex != null) {
          valueCleaners.put(valueCleanerRegex, valueCleanerValue);
        }
      }
    }

    paramMap.put("NAMECLEANERS", nameCleaners);
    paramMap.put("VALUECLEANERS", valueCleaners);
  }

  /**
   * Output the specification header section. This method is called in the head section of a job page which has selected a pipeline connection of the current type. Its purpose is to add the required
   * tabs to the list, and to output any javascript methods that might be needed by the job editing HTML.
   *
   * @param out                      is the output to which any HTML should be sent.
   * @param locale                   is the preferred local of the output.
   * @param os                       is the current pipeline specification for this connection.
   * @param connectionSequenceNumber is the unique number of this connection within the job.
   * @param tabsArray                is an array of tab names. Add to this array any tab names that are specific to the connector.
   */
  @Override
  public void outputSpecificationHeader(final IHTTPOutput out, final Locale locale, final Specification os, final int connectionSequenceNumber, final List<String> tabsArray)
      throws ManifoldCFException, IOException {
    final Map<String, Object> paramMap = new HashMap<>();
    paramMap.put("SEQNUM", Integer.toString(connectionSequenceNumber));

    tabsArray.add(Messages.getString(locale, "MetadataCleaner.CleanerTabName"));

    // Fill in the specification header map, using data from all tabs.
    fillInMetadataCleanerSpecification(paramMap, os);

    Messages.outputResourceWithVelocity(out, locale, EDIT_SPECIFICATION_JS, paramMap);
  }

  /**
   * Output the specification body section. This method is called in the body section of a job page which has selected a pipeline connection of the current type. Its purpose is to present the required
   * form elements for editing. The coder can presume that the HTML that is output from this configuration will be within appropriate <html>, <body>, and <form> tags. The name of the form is
   * "editjob".
   *
   * @param out                      is the output to which any HTML should be sent.
   * @param locale                   is the preferred local of the output.
   * @param os                       is the current pipeline specification for this job.
   * @param connectionSequenceNumber is the unique number of this connection within the job.
   * @param actualSequenceNumber     is the connection within the job that has currently been selected.
   * @param tabName                  is the current tab name.
   */
  @Override
  public void outputSpecificationBody(final IHTTPOutput out, final Locale locale, final Specification os, final int connectionSequenceNumber, final int actualSequenceNumber, final String tabName)
      throws ManifoldCFException, IOException {
    final Map<String, Object> paramMap = new HashMap<>();

    // Set the tab name
    paramMap.put("TABNAME", tabName);
    paramMap.put("SEQNUM", Integer.toString(connectionSequenceNumber));
    paramMap.put("SELECTEDNUM", Integer.toString(actualSequenceNumber));

    fillInMetadataCleanerSpecification(paramMap, os);

    Messages.outputResourceWithVelocity(out, locale, EDIT_SPECIFICATION_METADATA_CLEANER_HTML, paramMap);
  }

  /**
   * Process a specification post. This method is called at the start of job's edit or view page, whenever there is a possibility that form data for a connection has been posted. Its purpose is to
   * gather form information and modify the transformation specification accordingly. The name of the posted form is "editjob".
   *
   * @param variableContext          contains the post data, including binary file-upload information.
   * @param locale                   is the preferred local of the output.
   * @param os                       is the current pipeline specification for this job.
   * @param connectionSequenceNumber is the unique number of this connection within the job.
   * @return null if all is well, or a string error message if there is an error that should prevent saving of the job (and cause a redirection to an error page).
   */
  @Override
  public String processSpecificationPost(final IPostParameters variableContext, final Locale locale, final Specification os, final int connectionSequenceNumber) throws ManifoldCFException {

    final String seqPrefix = "s" + connectionSequenceNumber + "_";

    String x;

    // name cleaners
    x = variableContext.getParameter(seqPrefix + "namecleaner_count");
    if (x != null && x.length() > 0) {
      // About to gather the includefilter nodes, so get rid of the old ones.
      int i = 0;
      while (i < os.getChildCount()) {
        final SpecificationNode node = os.getChild(i);
        if (node.getType().equals(MetadataCleanerConfig.NODE_NAMECLEANER)) {
          os.removeChild(i);
        } else {
          i++;
        }
      }
      final int count = Integer.parseInt(x);
      i = 0;
      while (i < count) {
        final String prefix = seqPrefix + "namecleaner_";
        final String suffix = "_" + Integer.toString(i);
        final String op = variableContext.getParameter(prefix + "op" + suffix);
        if (op == null || !op.equals("Delete")) {
          // Gather the namecleaner.
          final String regex = variableContext.getParameter(prefix + MetadataCleanerConfig.ATTRIBUTE_REGEX + suffix);
          final String value = variableContext.getParameter(prefix + MetadataCleanerConfig.ATTRIBUTE_VALUE + suffix);
          final SpecificationNode node = new SpecificationNode(MetadataCleanerConfig.NODE_NAMECLEANER);
          node.setAttribute(MetadataCleanerConfig.ATTRIBUTE_REGEX, regex);
          node.setAttribute(MetadataCleanerConfig.ATTRIBUTE_VALUE, value);
          os.addChild(os.getChildCount(), node);
        }
        i++;
      }

      final String addop = variableContext.getParameter(seqPrefix + "namecleaner_op");
      if (addop != null && addop.equals("Add")) {
        final String regex = variableContext.getParameter(seqPrefix + "namecleaner_regex");
        final String value = variableContext.getParameter(seqPrefix + "namecleaner_value");
        final SpecificationNode node = new SpecificationNode(MetadataCleanerConfig.NODE_NAMECLEANER);
        node.setAttribute(MetadataCleanerConfig.ATTRIBUTE_REGEX, regex);
        node.setAttribute(MetadataCleanerConfig.ATTRIBUTE_VALUE, value);
        os.addChild(os.getChildCount(), node);
      }
    }

    // value cleaners
    x = variableContext.getParameter(seqPrefix + "valuecleaner_count");
    if (x != null && x.length() > 0) {
      // About to gather the includefilter nodes, so get rid of the old ones.
      int i = 0;
      while (i < os.getChildCount()) {
        final SpecificationNode node = os.getChild(i);
        if (node.getType().equals(MetadataCleanerConfig.NODE_VALUECLEANER)) {
          os.removeChild(i);
        } else {
          i++;
        }
      }
      final int count = Integer.parseInt(x);
      i = 0;
      while (i < count) {
        final String prefix = seqPrefix + "valuecleaner_";
        final String suffix = "_" + Integer.toString(i);
        final String op = variableContext.getParameter(prefix + "op" + suffix);
        if (op == null || !op.equals("Delete")) {
          // Gather the namecleaner.
          final String regex = variableContext.getParameter(prefix + MetadataCleanerConfig.ATTRIBUTE_REGEX + suffix);
          final String value = variableContext.getParameter(prefix + MetadataCleanerConfig.ATTRIBUTE_VALUE + suffix);
          final SpecificationNode node = new SpecificationNode(MetadataCleanerConfig.NODE_VALUECLEANER);
          node.setAttribute(MetadataCleanerConfig.ATTRIBUTE_REGEX, regex);
          node.setAttribute(MetadataCleanerConfig.ATTRIBUTE_VALUE, value);
          os.addChild(os.getChildCount(), node);
        }
        i++;
      }

      final String addop = variableContext.getParameter(seqPrefix + "valuecleaner_op");
      if (addop != null && addop.equals("Add")) {
        final String regex = variableContext.getParameter(seqPrefix + "valuecleaner_regex");
        final String value = variableContext.getParameter(seqPrefix + "valuecleaner_value");
        final SpecificationNode node = new SpecificationNode(MetadataCleanerConfig.NODE_VALUECLEANER);
        node.setAttribute(MetadataCleanerConfig.ATTRIBUTE_REGEX, regex);
        node.setAttribute(MetadataCleanerConfig.ATTRIBUTE_VALUE, value);
        os.addChild(os.getChildCount(), node);
      }
    }

    return null;
  }

  /**
   * View specification. This method is called in the body section of a job's view page. Its purpose is to present the pipeline specification information to the user. The coder can presume that the
   * HTML that is output from this configuration will be within appropriate <html> and <body> tags.
   *
   * @param out                      is the output to which any HTML should be sent.
   * @param locale                   is the preferred local of the output.
   * @param connectionSequenceNumber is the unique number of this connection within the job.
   * @param os                       is the current pipeline specification for this job.
   */
  @Override
  public void viewSpecification(final IHTTPOutput out, final Locale locale, final Specification os, final int connectionSequenceNumber) throws ManifoldCFException, IOException {
    final Map<String, Object> paramMap = new HashMap<>();
    paramMap.put("SEQNUM", Integer.toString(connectionSequenceNumber));

    fillInMetadataCleanerSpecification(paramMap, os);

    Messages.outputResourceWithVelocity(out, locale, VIEW_SPECIFICATION_HTML, paramMap);

  }

  protected static class SpecPacker {

    private final Map<String, String> nameCleaners = new HashMap<>();
    private final Map<String, String> valueCleaners = new HashMap<>();

    public SpecPacker(final Specification os) {
      for (int i = 0; i < os.getChildCount(); i++) {
        final SpecificationNode sn = os.getChild(i);

        if (sn.getType().equals(MetadataCleanerConfig.NODE_NAMECLEANER)) {
          final String regex = sn.getAttributeValue(MetadataCleanerConfig.ATTRIBUTE_REGEX);
          final String value = sn.getAttributeValue(MetadataCleanerConfig.ATTRIBUTE_VALUE);
          nameCleaners.put(regex, value);
        } else if (sn.getType().equals(MetadataCleanerConfig.NODE_VALUECLEANER)) {
          final String regex = sn.getAttributeValue(MetadataCleanerConfig.ATTRIBUTE_REGEX);
          final String value = sn.getAttributeValue(MetadataCleanerConfig.ATTRIBUTE_VALUE);
          valueCleaners.put(regex, value);
        }
      }
    }

    public String toPackedString() {
      final StringBuilder sb = new StringBuilder();

      // TODO
//      packList(sb, nameCleaners, '+');
//      packList(sb, valueCleaners, '+');

      return sb.toString();
    }

  }

  /**
   * Test if there is at least one regular expression that match with the provided sting
   *
   * @param regexList the list of regular expressions
   * @param str       the string to test
   * @return the first matching regex found or null if no matching regex
   */
  private String matchingRegex(final List<String> regexList, final String str) throws RegexException {
    for (final String regex : regexList) {
      try {
        final Pattern pattern = Pattern.compile(regex);
        final Matcher matcher = pattern.matcher(str);
        if (matcher.find()) {
          return regex;
        }
      } catch (final PatternSyntaxException e) {
        throw new RegexException(regex, "Invalid regular expression");
      }
    }
    return null;
  }

}
