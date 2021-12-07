# frozen_string_literal: true

require 'json'
require 'uri'
require 'net/http'

class CheckUrls < AbstractReport
  register_report(
    params: []
  )

  def log(s)
    Log.debug(s)
    @job.write_output(s)
  end

  def query
    results = []
    log('Checking Digital Object File Versions...')
    results.concat(fetch_notes(file_versions, TRUE))
    log("Done\n\n")
    log('Checking Resource Notes...')
    results.concat(fetch_notes(resource_notes))
    log("Done\n\n")
    log('Checking Archival Object Notes...')
    results.concat(fetch_notes(archival_object_notes))
    log("Done\n\n")
    log('Checking Digital Object Notes...')
    results.concat(fetch_notes(digital_object_notes))
    log("Done\n\n")
    log('Checking Digital Object Component Notes...')
    results.concat(fetch_notes(digital_object_component_notes))
    log("Done\n\n")
    log('Checking Subject Scope and Contents Notes...')
    results.concat(fetch_notes(subject_scope_notes, FALSE, TRUE))
    log("Done\n\n")
    log('Checking Agent Person Notes...')
    results.concat(fetch_notes(agent_person_notes))
    log("Done\n\n")
    log('Checking Agent Corporate Entity Notes...')
    results.concat(fetch_notes(agent_corporate_entity_notes))
    log("Done\n\n")
    log('Checking Agent Family Notes...')
    results.concat(fetch_notes(agent_family_notes))
    log("Done\n\n")
    log('Checking Agent Software Notes...')
    results.concat(fetch_notes(agent_software_notes))
    log("Done\n\n")
    results
  end

  def fetch_notes(query, digital_object = FALSE, raw_notes = FALSE)
    note_results = []
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
      if digital_object == TRUE
        identifier = result[:digital_object_id]
        note_type = 'Digital Object File Version'
        url = result[:file_uri]
        response = check_url(url, url)
      elsif raw_notes == TRUE
        notes = JSON.parse(result[:clean_notes].to_json)
        url, response, note_type = grab_urls(notes)
        note_type = notes['label'] if notes['label']
      else
        notes = JSON.parse(result[:clean_notes])
        url, response, note_type = grab_urls(notes)
        note_type = notes['label'] if notes['label']
      end
      unless response.nil?
        log("#{repository}, #{identifier}, #{note_type}, #{url}, #{response}")
        note_results << { Repository: repository, Identifier_Title: identifier, Note_Type: note_type, URL: url, Error_Code: response }
      end
    end
    note_results
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
      url_response = check_url(url_text, url_text) if url_text
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
      url_response = check_url(url_text, url_text) if url_text
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
      url_response = check_url(url_text, url_text) if url_text
      note_type = if notes['type']
                    notes['type']
                  elsif notes['jsonmodel_type']
                    notes['jsonmodel_type']
                  end
      [url_text, url_response, note_type]
    end
  end

  def match_regex(text)
    url_regex = %r{(?i)\b((?:https?:(?:/{1,3}|[a-z0-9%])|[a-z0-9.\-]+[.](?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)/)(?:[^\s()<>{}\[\]]+|\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\))+(?:\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\)|[^\s`!()\[\]{};:\'".,<>?«»“”‘’])|(?:(?<!@)[a-z0-9]+(?:[.\-][a-z0-9]+)*[.](?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)\b/?(?!@)))}
    if text.match url_regex
      matched_text = text.match url_regex
      matched_text.to_s
    end
  end

  def check_url(url, original_url, limit = 5)
    begin
      response_code = nil
      if limit.zero?
        uri = URI(original_url)
        response = Net::HTTP.get_response(uri)
        response_code = response.code.to_s
      else
        uri = URI(url)
        response = Net::HTTP.get_response(uri)
        case response
        when Net::HTTPRedirection
          location = response['location']
          log("Following redirect #{location}")
          check_url(location, original_url, limit - 1)
        else
          response_code = response.code.to_s if response.code.to_i != 200
        end
      end
    rescue StandardError => e
      response_code = e.message.to_s
    ensure
      response_code
    end
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
