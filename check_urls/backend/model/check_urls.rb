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
    write_csv('Date', 'w', 'Collection/Object', 'Note','Error Code', 'URL', 'Redirect?')
    # notes_content = db.fetch(file_versions)
    # notes_content.each do |result|
    #   do_url = result[:file_uri]
    #   error_code = check_url(do_url)
    #   write_csv(DateTime.now, 'a', notes_content[:title], 'Digital Object', error_code, do_url) if error_code != 200
    #   end
    grab_urls(resource_notes)
    # extref_results = db.fetch(extrefs)
    # info[:total_count] = extref_results.count
    # extref_results
  end

  def grab_urls(notes)
    notes_content = db.fetch(notes)
    notes_content.each do |result|
      notes = JSON.parse(result[:clean_notes])
      if notes['subnotes']
        notes['subnotes'].each do |subnotes|
          if subnotes.is_a?(Array)
            subnotes.each do |subnote|
              if subnote['content']
                url_text = match_regex(subnote['content'])
                if url_text
                  check_url(url_text)
                else
                  log('No URL found')
                end
              end
            end
          elsif subnotes['content']
            url_text = match_regex(subnotes['content'])
            if url_text
              check_url(url_text)
            end
          end
        end
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
        if url_text
          check_url(url_text)
        end
      end
    end
  end

  def check_url(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    code = response.code
    log("#{code.to_i} - #{uri}") if code.to_i != 200
    response.code
  rescue StandardError
    log("Error with URL: #{url}")
    "Error with URL: #{url}"
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
      SELECT resource.identifier, CONVERT(notes USING utf8) as clean_notes
      FROM note
      JOIN resource on resource.id = note.resource_id
    SQL
  end

  def archival_object_notes
    <<~SQL
      SELECT ao.id, ao.title, CONVERT(notes USING utf8) as clean_notes
      FROM note
      JOIN archival_object AS ao on ao.id = note.archival_object_id
    SQL
  end

  def digital_object_notes
    <<~SQL
      SELECT do.id, do.title, CONVERT(notes USING utf8) as clean_notes
      FROM note
      JOIN digital_object AS do on do.id = note.digital_object_id
    SQL
  end

  def digital_object_component_notes
    <<~SQL
      SELECT doc.id, doc.title, CONVERT(notes USING utf8) as clean_notes
      FROM note
      JOIN digital_object_component AS doc on doc.id = note.digital_object_component_id
    SQL
  end

  def agent_person_notes
    <<~SQL
      SELECT agp.id, CONVERT(notes USING utf8) as clean_notes
      FROM note 
      JOIN agent_person AS agp on agp.id = note.agent_person_id
    SQL
  end

  def agent_corporate_entity_notes
    <<~SQL
      SELECT agce.id, CONVERT(notes USING utf8) as clean_notes
      FROM note 
      JOIN agent_corporate_entity AS agce on agce.id = note.agent_corporate_entity_id
    SQL
  end

  def agent_family_notes
    <<~SQL
      SELECT agf.id, CONVERT(notes USING utf8) as clean_notes
      FROM note 
      JOIN agent_family AS agf on agf.id = note.agent_family_id
    SQL
  end

  def agent_software_notes
    <<~SQL
      SELECT ags.system_role, CONVERT(notes USING utf8) as clean_notes
      FROM note 
      JOIN agent_software AS ags on ags.id = note.agent_software_id
    SQL
  end

  def file_versions
    <<~SQL
      SELECT file_version.file_uri, digital_object.title, digital_object.digital_object_id
      FROM file_version
      JOIN digital_object on digital_object.id = file_version.digital_object_id
    SQL
  end

end
