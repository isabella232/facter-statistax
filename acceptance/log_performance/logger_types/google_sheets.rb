require 'google/apis/sheets_v4'
require 'googleauth'
require_relative '../utils'

class GoogleSheets
  APPLICATION_NAME = 'Google Sheets API'.freeze
  #env var with location of the token file needed to authenticate access to spreadsheet
  AUTHENTICATION_FILE_ENV_VAR = 'GOOGLE_APPLICATION_CREDENTIALS'.freeze

  def initialize(spreadsheet_id)
    @spreadsheet_id = spreadsheet_id
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(ENV[AUTHENTICATION_FILE_ENV_VAR]),
        scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    )
  end

  def name_and_path_of_pages
    pages = {}
    spreadsheet = @service.get_spreadsheet(@spreadsheet_id)
    spreadsheet.sheets.each do |sheet|
      pages[sheet.properties.title] = sheet.properties.sheet_id
    end
    pages
  end

  def create_pages(page_names)
    requests = []
    page_names.each do |page_name|
      add_sheet_request = Google::Apis::SheetsV4::AddSheetRequest.new
      add_sheet_request.properties = Google::Apis::SheetsV4::SheetProperties.new
      add_sheet_request.properties.title = page_name
      requests.append(add_sheet: add_sheet_request)
    end
    batch_update_spreadsheet(requests, "Created pages: #{page_names.join(", ")}")
  end

  def get_rows_from_page(page_name, range_in_table)
    normalized_range = A1Notation.convert_to_a1_notation(range_in_table)
    response = @service.get_spreadsheet_values(@spreadsheet_id, get_sheet_range_string(page_name, normalized_range))
    response.values.nil? ? [[]] : response.values
  end

  def write_to_page(rows_list, page_name, range)
    value_range = Google::Apis::SheetsV4::ValueRange.new(values: rows_list)
    result = @service.append_spreadsheet_value(@spreadsheet_id,
                                               get_sheet_range_string(page_name, A1Notation.convert_to_a1_notation(range)),
                                               value_range,
                                               value_input_option: 'USER_ENTERED')
    changed_cells = result.updates.updated_cells
    puts "#{changed_cells.nil? ? 0 : changed_cells} cells appended."
  end

  def add_row_with_merged_cells(row, page_name, page_id, range)
    write_to_page([row], page_name, range)
    merge_columns(page_id, row, range)
  end

  def format_range_by_condition(color, page_id, rule, range, success_message)
    conditional_format_request = Google::Apis::SheetsV4::AddConditionalFormatRuleRequest.new

    conditional_format_rule = Google::Apis::SheetsV4::ConditionalFormatRule.new
    conditional_format_rule.ranges = [create_grid_range(range, page_id)]

    rule[:values] = [Google::Apis::SheetsV4::ConditionValue.new(user_entered_value: rule[:values])]
    boolean_rule = Google::Apis::SheetsV4::BooleanCondition.new(rule)
    format = Google::Apis::SheetsV4::CellFormat.new(background_color: Google::Apis::SheetsV4::Color.new(color.code))
    conditional_format_rule.boolean_rule = Google::Apis::SheetsV4::BooleanRule.new(condition: boolean_rule, format: format)

    conditional_format_request.index = 0
    conditional_format_request.rule = conditional_format_rule

    batch_update_spreadsheet([add_conditional_format_rule: conditional_format_request], success_message)
  end

  private

  def batch_update_spreadsheet(requests_hashes_list, success_message)
    return if requests_hashes_list.empty?

    batch_update_spreadsheet_request = Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new
    batch_update_spreadsheet_request.requests = requests_hashes_list

    begin
      @service.batch_update_spreadsheet(@spreadsheet_id, batch_update_spreadsheet_request)
      puts success_message
    rescue Google::Apis::ClientError => error
      puts error.body
    end
  end

  def get_sheet_range_string(page_name, range)
    "#{page_name}!"\
    "#{range.start_column}#{range.start_row}:"\
    "#{range.end_column}#{range.end_row}"
  end

  #on a row, merges every empty cell with the next non empty cell
  def merge_columns(sheet_id, row_data, start_range)
    merge_requests = []
    merge_range = start_range.clone
    merge_range.end_column = merge_range.start_column
    row_data.each do |value|
      if value.empty?
        merge_range.end_column += 1
      else
        merge_requests.append(merge_cells: create_merge_request(merge_range, sheet_id))
        merge_range.start_column = merge_range.end_column += 1
      end
    end
    batch_update_spreadsheet(merge_requests, 'Merged cells.') unless merge_requests.empty?
  end

  def create_merge_request(merge_range, sheet_id)
    #for a merge request, you need to extend the right side column and row index. Eg: to merge cells at A1:B1 you need to give a range of A1:C2
    range = create_grid_range(merge_range, sheet_id)
    range.end_column_index += 1
    range.end_row_index += 1

    merge_cells_request = Google::Apis::SheetsV4::MergeCellsRequest.new
    merge_cells_request.merge_type = 'MERGE_ROWS'
    merge_cells_request.range = range
    merge_cells_request
  end

  def create_grid_range(range_in_table, sheet_id)
    range = Google::Apis::SheetsV4::GridRange.new
    range.sheet_id = sheet_id
    range.start_column_index = range_in_table.start_column
    range.start_row_index = range_in_table.start_row
    range.end_column_index = range_in_table.end_column
    range.end_row_index = range_in_table.end_row
    range
  end
end