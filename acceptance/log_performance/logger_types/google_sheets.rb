require 'google/apis/sheets_v4'
require 'googleauth'
require_relative '../logger_types/google_sheets'

class GoogleSheets
  APPLICATION_NAME = 'Google Sheets API'.freeze
  #env var with location of the token file needed to authenticate access to spreadsheet
  AUTHENTICATION_FILE_ENV_VAR = 'GOOGLE_APPLICATION_CREDENTIALS'.freeze
  @@column_letters = ('A'..'ZZ').to_a

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

  def get_rows_from_page(page_name, position_in_table)
    normalized_range = convert_to_a1_notation(position_in_table)
    response = @service.get_spreadsheet_values(@spreadsheet_id, get_sheet_range_string(page_name, normalized_range))
    response.values.nil? ? [[]] : response.values
  end

  def write_to_page(rows_list, page_name, position)
    value_range = Google::Apis::SheetsV4::ValueRange.new(values: rows_list)
    result = @service.append_spreadsheet_value(@spreadsheet_id,
                                               get_sheet_range_string(page_name, convert_to_a1_notation(position)),
                                               value_range,
                                               value_input_option: 'USER_ENTERED')
    changed_cells = result.updates.updated_cells
    puts "#{changed_cells.nil? ? 0: changed_cells} cells appended."
  end

  def add_row_with_merged_cells(row, page_name, page_id, position)
    write_to_page([row], page_name, position)
    merge_columns(page_id, row, position)
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

  def get_sheet_range_string(page_name, position)
    "#{page_name}!"\
    "#{position.start_column}#{position.start_row}:"\
    "#{position.end_column}#{position.end_row}"
  end

  def convert_to_a1_notation(position)
    end_column = if position.end_column.nil? or position.end_column == ''
                   ''
                 else
                   @@column_letters[position.end_column]
                 end
    PositionInTable.new(@@column_letters[position.start_column],
                        position.start_row + 1,
                        end_column,
                        position.end_row + 1)
  end

  #on a row, merges every empty cell with the next non empty cell
  def merge_columns(sheet_id, row_data, start_position)
    start_column_index = end_column_index = start_position.start_column
    merge_requests = []
    row_data.each do |value|
      if value.empty?
        end_column_index += 1
      else
        merge_requests.append(merge_cells: create_merge_request(start_column_index, end_column_index, sheet_id, start_position.start_row))
        start_column_index = end_column_index += 1
      end
    end
    batch_update_spreadsheet(merge_requests, 'Merged cells.') unless merge_requests.empty?
  end

  def create_merge_request(start_column, end_column, sheet_id, row_index)
    range = Google::Apis::SheetsV4::GridRange.new
    range.sheet_id = sheet_id
    range.start_column_index = start_column
    range.start_row_index = row_index
    #for a merge request, you need to extend the right side column and row index. Eg: to merge cells at A1:B1 you need to give a range of A1:C2
    range.end_column_index = end_column + 1
    range.end_row_index = row_index + 1

    merge_cells_request = Google::Apis::SheetsV4::MergeCellsRequest.new
    merge_cells_request.merge_type = 'MERGE_ROWS'
    merge_cells_request.range = range
    merge_cells_request
  end
end