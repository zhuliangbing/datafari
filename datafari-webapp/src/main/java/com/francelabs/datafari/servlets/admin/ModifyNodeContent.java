/*******************************************************************************
 *  * Copyright 2015 France Labs
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
package com.francelabs.datafari.servlets.admin;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.nio.file.Paths;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerException;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

import com.francelabs.datafari.service.indexer.IndexerServer;
import com.francelabs.datafari.service.indexer.IndexerServerManager;
import com.francelabs.datafari.service.indexer.IndexerServerManager.Core;
import com.francelabs.datafari.utils.Environment;
import com.francelabs.datafari.utils.ExecutionEnvironment;
import com.francelabs.datafari.utils.FileUtils;
import com.francelabs.datafari.utils.XMLUtils;

/**
 * This Servlet is used to print and modify the textContent of various nodes of
 * the solrConfig.xml It is called by SizeLimitations.html and by
 * AutocompleteConfiguration.html You must give as a parameter "type" the
 * content of the attribute "name" of the node you search DoGet is used to get
 * the value of the requested node cleans and creates the semaphores DoPost is
 * used to modify the value of the requested node There is one semaphore by node
 * requested since the start/restart of Datafari
 *
 * @author Alexis Karassev
 */
@WebServlet("/admin/ModifyNodeContent")
public class ModifyNodeContent extends HttpServlet {
  private static final long serialVersionUID = 1L;
  private final String server = Core.FILESHARE.toString();
  private final String env;
  private Document doc;
  private File config = null;
  private final static Logger LOGGER = LogManager.getLogger(ModifyNodeContent.class.getName());

  /**
   * @see HttpServlet#HttpServlet() Gets the path Checks if the required file
   *      exist
   */
  public ModifyNodeContent() {
    String environnement = Environment.getEnvironmentVariable("DATAFARI_HOME");

    if (environnement == null) { // If in development environment
      environnement = ExecutionEnvironment.getDevExecutionEnvironment();
    }
    env = environnement + "/solr/solrcloud/FileShare/conf";

    if (new File(env + "/solrconfig.xml").exists()) {
      config = new File(env + "/solrconfig.xml");
    }
  }

  /**
   * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse
   *      response) Used to release the semaphore Or create and or acquire the
   *      semaphore, then read the file to get the requested node
   */
  @Override
  protected void doGet(final HttpServletRequest request, final HttpServletResponse response) throws ServletException, IOException {
    try {
      final String type = request.getParameter("type");
      try {
        if (request.getParameter("sem") != null) { // If it's called
          // just to clean the
          // semaphore
          return;
        }
        if ((config == null) || !new File(env + "/solrconfig.xml").exists()) {// If
          // the
          // file
          // did
          // not
          // existed
          // when
          // the
          // constructor
          // was
          // run
          // Checks if it exists now
          if (!new File(env + "/solrconfig.xml").exists()) {
            LOGGER
                .error("Error while opening the configuration file, solrconfig.xml, in ModifyNodeContent doGet, please make sure this file exists at "
                    + env + "/solr/solrcloud/" + server + "/conf/ . Error 69033"); // If
            // not
            // an
            // error
            // is
            // printed
            final PrintWriter out = response.getWriter();
            out.append(
                "Error while opening the configuration file, please retry, if the problem persists contact your system administrator. Error Code : 69033");
            out.close();
            return;
          } else {
            config = new File(env + "/solrconfig.xml");
          }
        }

        final String attr = request.getParameter("attr");
        final DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
        final DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
        doc = dBuilder.parse(config); // Parse the solrconfig.xml
        final NodeList childNodes = doc.getChildNodes();
        final Element elem = (Element) run(childNodes, type, attr); // Search
        // for
        // the
        // requested
        // node
        final PrintWriter out = response.getWriter();
        out.append(elem.getTextContent()); // Return it's content
        out.close();
      } catch (ParserConfigurationException | SAXException e) {
        LOGGER.error("Error while parsing the solrconfig.xml, in ModifyNodeContent doGet, make sure the file is valid. Error 69034", e);
        final PrintWriter out = response.getWriter();
        out.append("Something bad happened, please retry, if the problem persists contact your system administrator. Error code : 69034");
        out.close();
        return;
      }

    } catch (final Exception e) {
      final PrintWriter out = response.getWriter();
      out.append("Something bad happened, please retry, if the problem persists contact your system administrator. Error code : 69514");
      out.close();
      LOGGER.error("Unindentified error in ModifyNodeContent doGet. Error 69514", e);
    }
  }

  /**
   * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse
   *      response) Read the file and search for the requested node, then set
   *      it's textContent to the parameter
   */
  @Override
  protected void doPost(final HttpServletRequest request, final HttpServletResponse response) throws ServletException, IOException {

	  IndexerServer server = null;
      try {
        server = IndexerServerManager.getIndexerServer(Core.FILESHARE);
      } catch (final IOException e1) {
        final PrintWriter out = response.getWriter();
        out.append(
            "Error while getting the Solr core, please make sure the core dedicated to FileShare has booted up. Error code : 69000");
        out.close();
        LOGGER.error(
            "Error while getting the Solr core in doGet, admin servlet, make sure the core dedicated to Promolink has booted up and is still called promolink or that the code has been changed to match the changes. Error 69000 ",
            e1);
        return;

      } catch (Exception e) {
		// TODO Auto-generated catch block
		e.printStackTrace();
	}
	  
	  
	  try {
      final String type = request.getParameter("type");
      final String value = request.getParameter("value");
      final String attr = request.getParameter("attr");
      Element elem;
      String oldNodeStr = null;
      try {
        final DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
        final DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
        doc = dBuilder.parse(config); // Parse the solrconfig.xml
        final NodeList childNodes = doc.getChildNodes();
        elem = (Element) run(childNodes, type, attr); // Get the
        // requested
        // Node
        oldNodeStr = XMLUtils.nodeToString(elem);
      } catch (ParserConfigurationException | SAXException e) {
        LOGGER.error("Error while parsing the solrconfig.xml, in ModifyNodeContent doPost, make sure the file is valid. Error 69035", e);
        final PrintWriter out = response.getWriter();
        out.append("Something bad happened, please retry, if the problem persists contact your system administrator. Error code : 69035");
        out.close();
        return;
      }
      try {
        elem.setTextContent(value); // Set the value of the node
        final String newNodeStr = XMLUtils.nodeToString(elem);
        String configStr = FileUtils.getFileContent(config);
        configStr = configStr.replace(oldNodeStr, newNodeStr);
        FileUtils.saveStringToFile(config, configStr); // Modify the
        // file
      } catch (final TransformerException e) {
        LOGGER.error("Error while modifying the solrconfig.xml, in ModifyNodeContent doPost. Error 69036", e);
        final PrintWriter out = response.getWriter();
        out.append("Something bad happened, please retry, if the problem persists contact your system administrator. Error code : 69036");
        out.close();
        return;
      }

      server.uploadConfig(Paths.get(env),Core.FILESHARE.toString());
      Thread.sleep(1000);
      server.reloadCollection(Core.FILESHARE.toString());
    } catch (final Exception e) {
      final PrintWriter out = response.getWriter();
      out.append("Something bad happened, please retry, if the problem persists contact your system administrator. Error code : 69515");
      out.close();
      LOGGER.error("Unindentified error in ModifyNodeContent doPost. Error 69515", e);
    }
  }

  private Node run(final NodeList child, final String type, final String attr) { // Function
    // to
    // search
    // for
    // a
    // node
    // by
    // it's
    // attribute
    // "name"
    // in
    // a
    // childList
    // and
    for (int i = 0; i < child.getLength(); i++) {
      String name = "";
      if (child.item(i).hasAttributes()) {
        final NamedNodeMap map = child.item(i).getAttributes();
        for (int j = 0; j < map.getLength(); j++) {
          if (map.item(j).getNodeName().equals(attr)) {
            name = map.item(j).getNodeValue();
          }
        }
        if (name.equals(type)) {
          return child.item(i);
        }
      }
      if (child.item(i).hasChildNodes()) {
        if (run(child.item(i).getChildNodes(), type, attr) != null) {
          return run(child.item(i).getChildNodes(), type, attr);
        }
      }
    }
    return null;
  }

}
