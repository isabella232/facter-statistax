# frozen_string_literal: true

module Configuration
  BEAKER_ENV_VARS = {
      'GOOGLE_APPLICATION_CREDENTIALS' => '/usr/app/google_sheets_credentials.json',
      'IS_GEM' => 'true'
  }
  SPREADSHEET_ID = '1giARlXsBSGhxIWRlThV8QfmybeAfaBrNRzdr9C0pvPw'
  USER_HOME_PATH = '/usr/app/'
  FACTER_NG_PROJECT_PATH = '/usr/app/facter-ng'
  STATISTAX_PROJECT_PATH = '/usr/app/facter-statistax/acceptance/'
  LOGS_FOLDER_PATH = '/usr/app/cron_logs'
  RUN_FAILS_LOG_NAME = '_run_failures'
  SCRIPT_ERRORS_LOG_NAME = '_script_failures'
  PRE_TESTS_LOG_NAME = '_all'
  VMPOOLERP_PLATFORMS = [
    'centos6-32',
    'centos6-64',
    'debian9-32',
    'debian9-64',
    'debian10-64',
    'fedora30-64',
    'fedora31-64',
    'osx1014-64',
    'osx1015-64',
    'redhat7-64',
    'redhatfips7-64',
    'redhat8-64',
    'sles12-64',
    'sles15-64',
    'solaris11-64',
    'solaris114-64',
    'ubuntu1604-32',
    'ubuntu1604-64',
    'ubuntu1804-64',
    'ubuntu2004-64',
    'windows2012r2-64',
    'windowsfips2012r2-64',
    'windows2019-64',
    'windows2016-64',
    'windows10ent-32',
    'windows10ent-64',
  ]
  NSPOOLER_PLATFORMS = {
      "aix61-POWER" => "aix-6.1-power",
      "aix71-POWER" => "aix-7.1-power",
      "aix72-POWER" => "aix-7.2-power",
      "redhat7-AARCH64" => "centos-7-arm64",
      "solaris11-SPARC"=>"solaris-11-sparc"
  }
end