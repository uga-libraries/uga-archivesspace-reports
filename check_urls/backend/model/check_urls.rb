# frozen_string_literal: true

require 'csv'
require 'json'
require 'uri'
require 'net/http'
require 'date'

class CheckUrls < AbstractReport
  register_report(
    params: []
  )

  def match_regex(text)
    url_regex = %r{(?i)\b((?:https?:(?:/{1,3}|[a-z0-9%])|[a-z0-9.\-]+[.](?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)/)(?:[^\s()<>{}\[\]]+|\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\))+(?:\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\)|[^\s`!()\[\]{};:\'".,<>?«»“”‘’])|(?:(?<!@)[a-z0-9]+(?:[.\-][a-z0-9]+)*[.](?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)\b/?(?!@)))}
    if text.match url_regex
      matched_text = text.match url_regex
      matched_text.to_s
    end
  end

  def query
    # write_csv('Date', 'w', 'Collection/Object', 'Note','Error Code', 'URL', 'Redirect?')
    log('Checking Digital Object File Versions')
    fetch_notes(file_versions, TRUE)
    log(' ')
    log('Checking Resource Notes')
    fetch_notes(resource_notes)
    log(' ')
    log('Checking Archival Object Notes')
    fetch_notes(archival_object_notes)
    log(' ')
    log('Checking Digital Object Notes')
    fetch_notes(digital_object_notes)
    log(' ')
    log('Checking Digital Object Component Notes')
    fetch_notes(digital_object_component_notes)
    log(' ')
    log('Checking Subject Scope and Contents Notes')
    fetch_notes(subject_scope_notes, FALSE, TRUE)
    # TODO: currently having problem 'not opened for reading' error with subject scope_note
    log(' ')
    log('Checking Agent Person Notes')
    fetch_notes(agent_person_notes)
    log(' ')
    log('Checking Agent Corporate Entity Notes')
    fetch_notes(agent_corporate_entity_notes)
    log(' ')
    log('Checking Agent Family Notes')
    fetch_notes(agent_family_notes)
    log(' ')
    log('Checking Agent Software Notes')
    fetch_notes(agent_software_notes)
    # extref_results = db.fetch(extrefs)
    # info[:total_count] = extref_results.count
    # extref_results
  end

  def fetch_notes(query, digital_object = FALSE, raw_notes = FALSE)
    notes_content = db.fetch(query)
    notes_content.each do |result|
      repository = result[:repository] || 'No Repository'
      full_id = ''
      identifier = if result[:identifier]
                     JSON.parse(result[:identifier])
                   elsif result[:title]
                     result[:title]
                   end
      if identifier.is_a?(Array)
        identifier.each do |id_part|
          full_id += "#{id_part}-" unless id_part.nil?
        end
        identifier = full_id.chomp('-')
      end
      # log(identifier)
      if digital_object == TRUE
        identifier = result[:digital_object_id]
        note_type = 'Digital Object File Version'
        url = result[:file_uri]
        response = check_url(url)
      elsif raw_notes == TRUE
        notes = JSON.parse(result[:clean_notes].to_json)
        url, response, note_type = grab_urls(notes)
        # log(url)
        # log(note_type)
        note_type = notes['label'] if notes['label']
      else
        notes = JSON.parse(result[:clean_notes])
        url, response, note_type = grab_urls(notes)
        # log(url)
        # log(note_type)
        note_type = notes['label'] if notes['label']
      end
      log("#{repository},#{identifier},#{note_type},#{url},#{response}") unless response.nil?
    end
  end

  def grab_urls(notes)
    url_text = nil
    combined_text = ''
    url_response = nil
    if notes['subnotes']
      notes['subnotes'].each do |subnote|
        if subnote.is_a?(Hash)
          subnote.each do |key, value|
            if value.is_a?(Array) && (key == 'content')
              value.each do |content_subnote|
                combined_text += "#{content_subnote} ".gsub('\n', '')
              end
              url_text = match_regex(combined_text)
            elsif value.is_a?(String) && (key == 'content')
              url_text = match_regex(value.gsub('\n', ''))
            end
          end
        end
      end
      url_response = check_url(url_text) if url_text
      note_type = if notes['type']
                    notes['type']
                  elsif notes['jsonmodel_type']
                    notes['jsonmodel_type']
                  end
      [url_text, url_response, note_type]
    elsif notes['content']
      if notes['content'].is_a?(Array)
        notes_combined = ''
        notes['content'].each do |note|
          notes_combined += "#{note} "
        end
        url_text = match_regex(notes_combined)
      else
        url_text = match_regex(notes['content'])
      end
      url_response = check_url(url_text) if url_text
      note_type = if notes['type']
                    notes['type']
                  elsif notes['jsonmodel_type']
                    notes['jsonmodel_type']
                  end
      [url_text, url_response, note_type]
    else
      if notes.is_a?(Array)
        notes.each do |subnote|
          combined_text += "#{subnote} "
        end
        url_text = match_regex(combined_text)
      else
        url_text = match_regex(notes)
      end
      url_response = check_url(url_text) if url_text
      note_type = if notes['type']
                    notes['type']
                  elsif notes['jsonmodel_type']
                    notes['jsonmodel_type']
                  end
      [url_text, url_response, note_type]
    end
  end

  def check_url(url)
    begin
      response_code = nil
      uri = URI(url)
      response = Net::HTTP.get_response(uri)
      response_code = response.code.to_s if response.code.to_i != 200
      # log("#{code} - #{uri}") if code.to_i != 200
    rescue StandardError
      response_code = "Error with URL: #{url}"
    ensure
      response_code
    end
  end

  def write_csv(start_date, mode, coll_num, note, err_code, url, redirect=None)
    CSV.open('check_urls_report.csv', mode) do |row|
      row << [start_date, coll_num, note, err_code, url, redirect]
    end
  end

  def page_break
    false
  end

  def log(s)
    Log.debug(s)
    @job.write_output(s)
  end

  def resource_notes
    <<~SQL
      SELECT repo.name as repository, resource.identifier, CONVERT(notes USING utf8) as clean_notes
      FROM note
      JOIN resource on resource.id = note.resource_id
      JOIN repository AS repo on resource.repo_id = repo.id
    SQL
  end

  def archival_object_notes
    <<~SQL
      SELECT repo.name as repository, ao.id, ao.title, CONVERT(notes USING utf8) as clean_notes
      FROM note
      JOIN archival_object AS ao on ao.id = note.archival_object_id
      JOIN repository AS repo on ao.repo_id = repo.id
    SQL
  end

  def digital_object_notes
    <<~SQL
      SELECT repo.name as repository, do.id, do.title, CONVERT(notes USING utf8) as clean_notes
      FROM note
      JOIN digital_object AS do on do.id = note.digital_object_id
      JOIN repository AS repo on do.repo_id = repo.id
    SQL
  end

  def digital_object_component_notes
    <<~SQL
      SELECT repo.name as repository, doc.id, doc.title, CONVERT(notes USING utf8) as clean_notes
      FROM note
      JOIN digital_object_component AS doc on doc.id = note.digital_object_component_id
      JOIN repository AS repo on doc.repo_id = repo.id
    SQL
  end

  def subject_scope_notes
    <<~SQL
      SELECT subject.title, subject.id, CONVERT(subject.scope_note USING utf8) as clean_notes
      FROM subject
      WHERE scope_note IS NOT NULL
    SQL
  end

  def agent_person_notes
    <<~SQL
      SELECT agp.id, np.sort_name as title, CONVERT(notes USING utf8) as clean_notes
      FROM note
      JOIN agent_person AS agp on agp.id = note.agent_person_id
      JOIN name_person AS np on agp.id = np.agent_person_id
    SQL
  end

  def agent_corporate_entity_notes
    <<~SQL
      SELECT agce.id, nce.sort_name as title, CONVERT(notes USING utf8) as clean_notes
      FROM note
      JOIN agent_corporate_entity AS agce on agce.id = note.agent_corporate_entity_id
      JOIN name_corporate_entity AS nce on agce.id = nce.agent_corporate_entity_id
    SQL
  end

  def agent_family_notes
    <<~SQL
      SELECT agf.id, nf.sort_name as title, CONVERT(notes USING utf8) as clean_notes
      FROM note
      JOIN agent_family AS agf on agf.id = note.agent_family_id
      JOIN name_family AS nf on agf.id = nf.agent_family_id
    SQL
  end

  def agent_software_notes
    <<~SQL
      SELECT ags.system_role, ns.sort_name as title, CONVERT(notes USING utf8) as clean_notes
      FROM note
      JOIN agent_software AS ags on ags.id = note.agent_software_id
      JOIN name_software AS ns on ags.id = ns.agent_software_id
    SQL
  end

  def file_versions
    <<~SQL
      SELECT repo.name as repository, file_version.file_uri, digital_object.title, digital_object.digital_object_id
      FROM file_version
      JOIN digital_object on digital_object.id = file_version.digital_object_id
      JOIN repository AS repo on digital_object.repo_id = repo.id
    SQL
  end

end
