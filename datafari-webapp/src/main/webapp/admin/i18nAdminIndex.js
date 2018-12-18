$(function($) {

  // 'this' is the document (adminUI index page) here
  var elm = $(this);

  // Set the language parameter for main search page
  elm.find('#datafariHomePageSearchUiLink').prop('href', "../index.jsp?lang=" + window.i18n.language);

  // Set the language parameter for search page
  elm.find('#datafariSearchUiLink').prop('href', "/Datafari/Search?lang=" + window.i18n.language);

  // Statistics
  elm.find('#usagesAnalysis-AdminUI').html(window.i18n.msgStore['adminUI-UsagesAnalysis']);
  elm.find('#corpusAnalysis-AdminUI').html(window.i18n.msgStore['adminUI-CorpusAnalysis']);
  elm.find('#corpusOTAnalysis-AdminUI').html(window.i18n.msgStore['adminUI-CorpusOTAnalysis']);
  elm.find('#queriesAnalysis-AdminUI').html(window.i18n.msgStore['adminUI-QueriesAnalysis']);
  elm.find('#systemAnalysis-AdminUI').html(window.i18n.msgStore['adminUI-SystemAnalysis']);
  elm.find('#problematicFiles-AdminUI').html(window.i18n.msgStore['adminUI-ProblematicFiles']);
  elm.find('#logsAnalysis-AdminUI').html(window.i18n.msgStore['adminUI-LogsAnalysis']);

  elm.find('#relevancySetupFile-AdminUI').html(window.i18n.msgStore['adminUI-RelevancySetupFile']);

  elm.find('#datafariSearchUiLink').html(window.i18n.msgStore['adminUI-SearchPage']);
  elm.find('#welcomeAdminUiMsg').html(window.i18n.msgStore['adminUI-Welcome']);
  elm.find('#logout-AdminUI').html(window.i18n.msgStore['logoutAdminUiLink']);
  elm.find('#myAccount-AdminUI').html(window.i18n.msgStore['adminUI-MyAccount']);
  elm.find('#alerts-AdminUI').html(window.i18n.msgStore['adminUI-Alerts']);
  elm.find('#favorites-AdminUI').html(window.i18n.msgStore['adminUI-Favorites']);
  elm.find('#searches-AdminUI').html(window.i18n.msgStore['adminUI-Searches']);
  elm.find('#connectors-AdminUI').html(window.i18n.msgStore['adminUI-Connectors']);
  elm.find('#MCFAdmin-AdminUI').html(window.i18n.msgStore['adminUI-Connectors-Admin']);
  elm.find('#MCFPassword-AdminUI').html(window.i18n.msgStore['MCFPassword-AdminUI']);
  elm.find('#MCFBackupRestore-AdminUI').html(window.i18n.msgStore['adminUI-Connectors-BackupRestore']);
  elm.find('#MCFSimplified-AdminUI').html(window.i18n.msgStore['adminUI-Connectors-MCFSimplified']);
  elm.find('#elkConfiguration-AdminUI').html(window.i18n.msgStore['adminUI-ELKConf']);
  elm.find('#searchEngineAdmin-AdminUI').html(window.i18n.msgStore['adminUI-SearchEngineAdmin']);
  elm.find('#solrAdmin-AdminUI').html(window.i18n.msgStore['adminUI-SolrAdmin']);
  elm.find('#alertAdmin-AdminUI').html(window.i18n.msgStore['adminUI-AlertAdmin']);
  elm.find('#indexField-AdminUI').html(window.i18n.msgStore['adminUI-IndexField']);
  elm.find('#schemaAnalysis-AdminUI').html(window.i18n.msgStore['adminUI-SchemaAnalysis']);
  elm.find('#sizeLimitation-AdminUI').html(window.i18n.msgStore['adminUI-SizeLimitation']);
  elm.find('#autocompleteConfig-AdminUI').html(window.i18n.msgStore['adminUI-AutocompleteConfig']);
  elm.find('#searchEngineConfig-AdminUI').html(window.i18n.msgStore['adminUI-SearchEngineConfig']);

  elm.find('#departmentSearchConf-AdminUI').html(window.i18n.msgStore['adminUI-DepartmentSearchConf']);
  elm.find('#queryElevator-AdminUI').html(window.i18n.msgStore['adminUI-QueryElevator']);
  elm.find('#promoLinks-AdminUI').html(window.i18n.msgStore['adminUI-PromoLinks']);
  elm.find('#synonyms-AdminUI').html(window.i18n.msgStore['adminUI-Synonyms']);
  elm.find('#stopwords-AdminUI').html(window.i18n.msgStore['adminUI-Stopwords']);
  elm.find('#protwords-AdminUI').html(window.i18n.msgStore['adminUI-Protwords']);
  elm.find('#fieldWeight-AdminUI').html(window.i18n.msgStore['adminUI-FieldWeight']);
  elm.find('#fieldWeightAPI-AdminUI').html(window.i18n.msgStore['adminUI-FieldWeight']);
  elm.find('#facetConfig-AdminUI').html(window.i18n.msgStore['adminUI-FacetConfig']);
  elm.find('#deduplication-AdminUI').html(window.i18n.msgStore['adminUI-Deduplication']);
  elm.find('#likesFavoritesSearchEng-AdminUI').html(window.i18n.msgStore['adminUI-LikesAndFavorites']);
  elm.find('#servers-AdminUI').html(window.i18n.msgStore['adminUI-Servers']);
  elm.find('#userManagement-AdminUI').html(window.i18n.msgStore['adminUI-UserManagement']);
  elm.find('#modifyUsers-AdminUI').html(window.i18n.msgStore['adminUI-ModifyUsers']);
  elm.find('#modifyDepartment-AdminUI').html(window.i18n.msgStore['adminUI-UserDepartment']);
  elm.find('#addUser-AdminUI').html(window.i18n.msgStore['adminUI-AddUser']);
  elm.find('#zookeeper-AdminUI').html(window.i18n.msgStore['adminUI-Zookeeper']);

  $("#logs-AdminUI").html(window.i18n.msgStore['adminUI-Logs']);
  $("#downloadLogs-AdminUI").html(window.i18n.msgStore['adminUI-Download-Logs']);

  // Active Directory
  elm.find('#activeDirectoryManagement-AdminUI').html(window.i18n.msgStore['adminUI-activeDirectoryManagement']);
  elm.find('#ADConfig-AdminUI').html(window.i18n.msgStore['adminUI-ADConfig']);
  elm.find('#testADAuthority-AdminUI').html(window.i18n.msgStore['adminUI-testADAuthority']);

  $("#licence-AdminUI").html(window.i18n.msgStore['adminUI-Licence']);
});