module Tables

  def get_index_for_column_head(panel, table_index, strg)
    rgx = Regexp.new(strg)
    panel.tables[table_index].each do |row|
      if row.text =~ rgx
        index = 1
        row.each do |cell|
          if cell.text =~ rgx
            return index
          end
          index += 1
        end
      end
    end
  end

  def get_index_of_last_row(table, pad = 2, every = 1)
    index = calc_index(table.row_count, every)
    index = index.to_s.rjust(pad, '0')
    #debug_to_log("#{__method__}: index='#{index}' row_count=#{table.row_count} pad=#{pad} every=#{every}")
    index
  end

  alias get_index_for_last_row get_index_of_last_row

  def get_index_of_last_row_with_text(table, strg, column_index = nil)
    debug_to_log("#{__method__}: #{get_callers(5)}")
    msg = "Find last row in table :id=#{table.id} with text '#{strg}'"
    msg << " in column #{column_index}" if column_index
    dbg = "#{__method__}: #{table.id} text by row "
    dbg << "in column #{column_index}" if column_index
    index    = 0
    found    = false
    at_index = 0
    #row_count = table.row_count
    table.rows.each do |row|
      cell_count = get_cell_count(row)
      index      += 1
      text       = ''
      if column_index
        col_idx = column_index.to_i
        if cell_count >= col_idx
          text = row[col_idx].text
        end
      else
        text = row.text
      end
      dbg << "\n#{index}. [#{text}]"
      if text =~ /#{strg}/
        found    = true
        at_index = index
      end
    end
    debug_to_log(dbg)
    if found
      passed_to_log("#{msg} at index #{index}.")
      at_index
    else
      failed_to_log("#{msg}")
      nil
    end
  rescue
    failed_to_log("Unable to #{msg}. '#{$!}'")
  end

  alias get_index_for_last_row_with_text get_index_of_last_row_with_text

  def get_index_of_row_with_text(table, strg, column_index = nil, fail_if_found = false)
    debug_to_log("#{__method__}: #{get_callers(5)}")
    if fail_if_found
      msg = 'No '
    else
      msg = 'Find '
    end
    msg << "row in table :id=#{table.id} with text '#{strg}'"
    msg << " in column #{column_index}" if column_index
    dbg = "#{__method__}: #{table.id} text by row "
    dbg << "in column #{column_index}" if column_index
    index = 0
    found = false
    table.rows.each do |row|
      cell_count = row.cells.length
      index      += 1
      text       = ''
      if column_index
        col_idx = column_index.to_i
        if cell_count >= col_idx
          text = row[col_idx].text
        end
      else
        text = row.text
      end
      dbg << "\n#{index}. [#{text}]"
      if text =~ /#{strg}/
        found = true
        break
      end
    end
    debug_to_log(dbg)
    if found
      if fail_if_found
        failed_to_log("#{msg} at index #{index}.")
      else
        passed_to_log("#{msg} at index #{index}.")
      end
      index
    else
      if fail_if_found
        passed_to_log("#{msg}")
      else
        failed_to_log("#{msg}")
      end
      nil
    end
  rescue
    failed_to_log("Unable to #{msg}. '#{$!}'")
  end

  def get_index_of_row_with_textfield_value(table, strg, how, what, column_index = nil)
    msg = "Find row in table :id=#{table.id} with value '#{strg}' in text_field #{how}=>'#{what} "
    msg << " in column #{column_index}" if column_index
    index = 0
    found = false
    table.rows.each do |row|
      cell_count = get_cell_count(row)
      index      += 1
      text       = ''
      if column_index
        col_idx = column_index.to_i
        if cell_count >= col_idx
          if  row[col_idx].text_field(how, what).exists?
            value = row[col_idx].text_field(how, what).value
          end
        end
      else
        if  row.text_field(how, what).exists?
          value = row.text_field(how, what).value
          sleep(0.25)
        end
      end
      if value and value =~ /#{strg}/
        found = true
        break
      end
    end
    if found
      passed_to_log("#{msg} at index #{index}.")
    else
      failed_to_log("#{msg}")
    end
    index
  rescue
    failed_to_log("Unable to #{msg}. '#{$!}'")
  end

  def get_index_for_table_containing_text(browser, strg, ordinal = 1)
    msg   = "Get index for table containing text '#{strg}'"
    index = 0
    found = 0
    browser.tables.each do |t|
      index += 1
      if t.text =~ /#{strg}/
        found += 1
        if ordinal > 0 and found == ordinal
          break
        end
      end
    end
    if found
      passed_to_log("#{msg}: #{index}")
      index
    else
      passed_to_log("#{msg}.")
      nil
    end
  rescue
    failed_to_log("Unable to find index of table containing text '#{strg}' '#{$!}' ")
  end

  def get_table_containing_text(browser, strg, ordinal = 1)
    msg   = "Get table #{ordinal} containing text '#{strg}'"
    index = get_index_for_table_containing_text(browser, strg, ordinal)
    if index
      passed_to_log(msg)
      browser.tables[index]
    else
      failed_to_log(msg)
      nil
    end
  rescue
    failed_to_log("Unable to find index of table containing text '#{strg}' '#{$!}' ")
  end

  def get_cell_text_from_row_with_string(nc_element, table_index, column_index, strg)
    rgx  = Regexp.new(strg)
    text = ''
    debug_to_log("strg:'#{strg}', rgx:'#{rgx}', table_index:'#{table_index}', column_index:'#{column_index}'")
    nc_element.tables[table_index].each do |row|
      cell_count = get_cell_count(row)
      if cell_count >= column_index
        #TODO this assumes column 1 is a number column
        #        debug_to_log("row:'#{row.cells}'")
        cell_1 = row[1].text
        if cell_1 =~ /\d+/
          row_text = row.text
          if row_text =~ rgx
            text = row[column_index].text
            break
          end
        end
      end
    end
    text
  end

  def count_rows_with_string(container, table_index, strg)
    hit = 0
    container.tables[table_index].each do |row|
      if get_cell_count(row) >= 1
        #        debug_to_log("#{__method__}: #{row.text}")
        #TODO this assumes column 1 is a number column
        if row[1].text =~ /\d+/
          if row.text =~ /#{strg}/i
            hit += 1
            debug_to_log("#{__method__}: #{row.text}")
          end
        end
      end
    end
    debug_to_log("#{__method__}: hit row count: #{hit}")
    hit
  end

  def fetch_array_for_table_column(nc_element, table_index, column_index)
    ary = []
    nc_element.tables[table_index].each do |row|
      if get_cell_count(row) >= column_index
        #TODO this assumes column 1 is a number column
        if row[1].text =~ /\d+/
          ary << row[column_index].text
        end
      end
    end
    return ary f
  end

  def fetch_hash_for_table_column(table, column_index, start_row = 2)
    hash      = Hash.new
    row_count = 0
    table.each do |row|
      row_count += 1
      if get_cell_count(row) >= column_index
        if row_count >= start_row
          hash[row_count] = row[column_index].text
        end
      end
    end
    hash
  end

  def get_row_cells_text_as_array(row)
    ary = []
    row.each do |cell|
      ary << cell.text
    end
    ary
  end

  def count_data_rows(container, data_index, column_index)
    cnt   = 0
    #  get_objects(container, :tables, true)
    table = container.tables[data_index]
    dump_table_and_rows(table)
    if table
      table.rows.each do |row|
        if get_cell_count(row) >= column_index
          #TODO this assumes column 1 is a number column
          if row[column_index].text =~ /\d+/
            cnt += 1
          end
        end
      end
    end
    sleep_for(2)
    cnt
  end

  def get_cell_count(row)
    #    if @browserAbbrev == 'IE' or $use_firewatir
    row.cells.length
    #    else
    #      row.cell_count
    #    end
  end

  def exercise_sorting(browser, columnList, desc = '')
    #TODO put rescue inside the do loop
    #parameters: browser and a list of column link text values
    #example: exercise_sorting(browser,['Division', 'Payee', 'Date'], 'Sortable columns on this page')
    columnList.each do |column|
      click(browser, :link, :text, column, desc)
    end
  end

  alias validate_sorting exercise_sorting

  def verify_column_sort(browser, nc_element, strg, table_index, column_index=nil)
    mark_testlevel("Verify Column Sort '#{strg}'", 3)
    if not column_index
      column_index = get_index_for_column_head(nc_element, table_index, strg)
    end

    if column_index
      bfr_ary = fetch_array_for_table_column(nc_element, table_index, column_index)
      if strg =~ /date/i
        exp_ary = bfr_ary.sort { |x, y| Date.parse(x) <=> Date.parse(y) }
      else
        exp_ary = bfr_ary.sort { |x, y| x.gsub(',', '') <=> y.gsub(',', '') }
      end

      if click_text(browser, strg)
        if column_index
          sleep_for(2.5)
        else
          sleep_for(1)
        end
        act_ary = fetch_array_for_table_column(nc_element, table_index, column_index)

        if exp_ary == act_ary
          passed_to_log("Click on column '#{strg}' produces expected sorted list.")
          true
        else
          failed_to_log("Click on column '#{strg}' fails to produce expected sorted list.")
          debug_to_log("Original order ['#{bfr_ary.join("', '")}']")
          debug_to_log("Expected order ['#{exp_ary.join("', '")}']")
          debug_to_log("  Actual order ['#{act_ary.join("', '")}']")
        end
      end
    else
      failed_to_log("Unable to locate column index for '#{strg}' to verify sort.")
    end
  rescue
    failed_to_log("Unable to verify sort on column '#{strg}'. #{$!}")
  end

  def verify_column_sort_temp_ff(browser, strg, table_index, column_index=nil)
    mark_testlevel("Verify Column Sort '#{strg}'", 3)

    if not column_index
      column_index = get_index_for_column_head(browser, table_index, strg)
    end

    if column_index
      bfr_ary = fetch_array_for_table_column(browser, table_index, column_index)
      if strg =~ /date/i
        exp_ary = bfr_ary.sort { |x, y| Date.parse(x) <=> Date.parse(y) }
      else
        exp_ary = bfr_ary.sort { |x, y| x.gsub(',', '') <=> y.gsub(',', '') }
      end

      if click_text(browser, strg)
        sleep_for(3)
        act_ary = fetch_array_for_table_column(browser, table_index, column_index)

        if exp_ary == act_ary
          passed_to_log("Click on column '#{strg}' produces expected sorted list.")
          true
        else
          failed_to_log("Click on column '#{strg}' fails to produce expected sorted list.")
          debug_to_log("Original order ['#{bfr_ary.join("', '")}']")
          debug_to_log("Expected order ['#{exp_ary.join("', '")}']")
          debug_to_log("  Actual order ['#{act_ary.join("', '")}']")
        end
      end
    else
      failed_to_log("Unable to locate column index for '#{strg}' to verify sort.")
    end
  rescue
    failed_to_log("Unable to verify sort on column '#{strg}'. #{$!}")
  end

  #TODO unstub
  def verify_column_hidden(browser, panel, table_index, column_name)
    passed_to_log("TEST STUBBED: Column '#{column_name}' is hidden.")
    return true
    #    id = @column_data_display_ids[column_name]
    #    ok = false

    #    row = panel.tables[2][3]

    #    row.each do |cell|
    ##      strg = cell.to_s
    ##      insp = cell.inspect
    ##      ole  = cell.ole_object
    ##      anId = cell.attribute_value(:id)
    #      text = cell.text
    #      if text =~ /#{id}/
    #        if cell.to_s =~ /hidden/
    #          passed_to_log( "Column '#{column_name}' is hidden.")
    #        else
    #          failed_to_log( "Column '#{column_name}' is not hidden.")
    #        end
    #        ok = true
    #      end
    #    end
    #    if not ok
    #      failed_to_log( "Column '#{column_name}' not found.")
    #    end
    #  rescue
    #    failed_to_log("Unable to verify column '#{column_name}' is hidden: '#{$!}' (#{__LINE__})")
  end

  #TODO unstub
  def verify_column_hidden_temp_ff(browser, data_index, row_index, column_name)
    passed_to_log("TEST STUBBED: Column '#{column_name}' is hidden.")
    return true

    row     = browser.tables[data_index][row_index]
    #    debug_to_log( "#{row.to_a}")
    #TODO cells are all still there in the row.  Need to check for clue to hidden/visible in other tag attributes
    act_ary = get_row_cells_text_as_array(row)

    if not act_ary.include?(column_name)
      passed_to_log("Column '#{column_name}' is hidden.")
    else
      failed_to_log("Column '#{column_name}' is not hidden.")
    end
  end

  #TODO unstub
  def verify_column_visible_temp_ff(browser, data_index, row_index, column_name)
    passed_to_log("TEST STUBBED: Column '#{column_name}' is visible.")
    return true

    row     = browser.tables[data_index][row_index]
    #TODO cells are all still there in the row.  Need to check for clue to hidden/visible in other tag attributes
    act_ary = get_row_cells_text_as_array(row)

    if act_ary.include?(column_name)
      passed_to_log("Column '#{column_name}' is visible.")
    else
      failed_to_log("Column '#{column_name}' is not visible.")
    end
  end

  #TODO unstub
  def verify_column_visible(browser, panel, table_index, column_name)

    passed_to_log("TEST STUBBED: Column '#{column_name}' is visible.")
    return true

      #    id = @column_data_display_ids[column_name]
      #    ok  = false
      #    row = panel.tables[table_index][1]
      #    row.each do |cell|
      #      if cell.id == id
      #        if not cell.to_s =~ /hidden/
      #          passed_to_log("Column '#{column_name}' is visible.")
      #        else
      #          failed_to_log("Column '#{column_name}' is not visible.")
      #        end
      #        ok = true
      #      end
      #    end
      #    if not ok
      #      failed_to_log("Column '#{column_name}' not found.")
      #    end
  rescue
    failed_to_log("Unable to verify column '#{column_name} is visible': '#{$!}' (#{__LINE__})")
  end

  def verify_column_order(browser, table_index, row_index, exp_ary)
    mark_testlevel("Verify Column Order", 2)
    row     = browser.tables[table_index][row_index]
    act_ary = get_row_cells_text_as_array(row)

    if exp_ary == act_ary
      passed_to_log("Column order [#{act_ary.join(', ')}] appeared as expected.")
    else
      failed_to_log("Column order [#{act_ary.join(', ')}] not as expected [#{exp_ary.join(', ')}].")
    end
    sleep_for(1)
  end

end
