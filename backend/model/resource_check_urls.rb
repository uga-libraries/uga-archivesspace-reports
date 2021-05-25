# frozen_string_literal: true

require 'csv'
require 'uri'
require 'net/http'

class ResourceCheckUrls < AbstractReport
  register_report(
    params: []
  )

  def match_regex(text)
    if text =~ %r[(?i)\b((?:https?:(?:/{1,3}|[a-z0-9%])|[a-z0-9.\-]+[.](?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)/)(?:[^\s()<>{}\[\]]+|\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\))+(?:\([^\s()]*?\([^\s()]+\)[^\s()]*?\)|\([^\s]+?\)|[^\s`!()\[\]{};:\'".,<>?«»“”‘’])|(?:(?<!@)[a-z0-9]+(?:[.\-][a-z0-9]+)*[.](?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)\b/?(?!@)))]
      text
    end
  end

  def query
    write_csv('Report Path', 'Date', 'w', 'Collection Number', 'Note', 
              'Error Code', 'URL', 'Redirect?')
    log('hello world')
    check_urls
    # extref_results = db.fetch(extrefs)
    # info[:total_count] = extref_results.count
    # extref_results
  end

  # def extrefs
  #   <<~SOME_SQL
  #     SELECT CONVERT(notes USING utf8) AS clean_notes FROM note HAVING instr(clean_notes, 'extref')
  #   SOME_SQL
  # end

  def resource_notes
    <<~SOME_SQL
      SELECT IF(note.resource_id is not NULL, resource.id, "NULL"), 
      CONVERT(notes USING utf8) as clean_notes 
      FROM note 
      JOIN resource on resource.id = note.resource_id
    SOME_SQL
  end

  def archival_object_notes
    <<~SOME_SQL
      SELECT IF(note.archival_object_id is not NULL, note.archival_object_id, "NULL"), 
      CONVERT(notes USING utf8) as clean_notes 
      FROM note 
      JOIN archival_object on archival_object.id = note.archival_object_id
    SOME_SQL
  end

  def digital_object_notes
    <<~SQL
      SELECT IF(note.digital_object_id is not NULL, note.digital_object_id, "NULL"), 
      CONVERT(notes USING utf8) as clean_notes 
      FROM note 
      JOIN digital_object on digital_object.id = note.digital_object_id
    SQL
  end

  def digital_object_component_notes
    <<~SQL
      SELECT IF(note.digital_object_component_id is not NULL, note.digital_object_component_id, "NULL"), 
      CONVERT(notes USING utf8) as clean_notes 
      FROM note 
      JOIN digital_object_component on digital_object_component.id = note.digital_object_component_id
    SQL
  end

  def agent_person_notes
    <<~SQL
      SELECT IF(note.agent_person_id is not NULL, note.agent_person_id, "NULL"), 
      CONVERT(notes USING utf8) as clean_notes 
      FROM note 
      JOIN agent_person on agent_person.id = note.agent_person_id
    SQL
  end

  def agent_corporate_entity_notes
    <<~SQL
      SELECT IF(note.agent_corporate_entity_id is not NULL, note.agent_corporate_entity_id, "NULL"), 
      CONVERT(notes USING utf8) as clean_notes 
      FROM note 
      JOIN agent_corporate_entity on agent_corporate_entity.id = note.agent_corporate_entity_id
    SQL
  end

  def agent_family_notes
    <<~SQL
      SELECT IF(note.agent_family_id is not NULL, note.agent_family_id, "NULL"), 
      CONVERT(notes USING utf8) as clean_notes 
      FROM note 
      JOIN agent_family on agent_family.id = note.agent_family_id
    SQL
  end

  def agent_software_notes
    <<~SQL
      SELECT IF(note.agent_software_id is not NULL, note.agent_software_id, "NULL"), 
      CONVERT(notes USING utf8) as clean_notes 
      FROM note 
      JOIN agent_software on agent_software.id = note.agent_software_id
    SQL
  end

  def file_versions
    <<~SQL
      SELECT file_version.file_uri, digital_object.title, digital_object.digital_object_id
      FROM file_version
      JOIN digital_object on digital_object.id = file_version.digital_object_id
    SQL
  end

  def check_urls
    notes_content = db.fetch(resource_notes)
    log(notes_content)
    notes_content.each do |result|
      if result.include? 'content'
        url_text = match_regex(result['content'])
        uri = URI(url_text)
        result = Net::HTTP.get_response(uri)
        # write_csv('report path', Date.today, 'a', )
        log result unless (result = 200)
      elsif result.include? 'subnotes'
        result['subnotes'].each do |subnote|
          url_text = match_regex(subnote['content']) if subnote.include? 'content'
          uri = URI(url_text)
          result = Net::HTTP.get_response(uri)
          log result unless (result = 200)
        end
      end
    end
  end

  def write_csv(report_path, start_date, mode, coll_num, note, err_code, url, redirect=None)
    CSV.open('resource_check_urls_report.csv', mode) do |row|
      row << [report_path, start_date, coll_num, note, err_code, url, redirect]
    end
  end

  def page_break
    false
  end

  def log(s)
    Log.debug(s)
    @job.write_output(s)
  end

end
