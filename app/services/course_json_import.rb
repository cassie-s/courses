class CourseJsonImport
  def initialize(json)
    self.json = json
  end

  def run
    json["courses"].each do |course_json|
      course_attr = Hash.new
      course_attr = course_json.slice("title", "description", "course_id", "catalog_number")

      campus = Campus.where(abbreviation: json["campus"]["abbreviation"]).first

      term = Term.where(strm: json["term"]["strm"]).first

      subject = Subject.find_or_create_by(course_json["subject"].slice("subject_id", "description").merge({campus_id: campus.id, term_id: term.id}))
      course_attr[:subject_id] = subject.id

      equivalency_json = course_json["equivalency"]
      if equivalency_json
        equivalency = Equivalency.find_by(equivalency_json.slice("equivalency_id"))
        course_attr[:equivalency_id] = equivalency.id
      end

      course = Course.create(course_attr)

      attributes = course_json["course_attributes"].map { |a| CourseAttribute.find_by(attribute_id: a["attribute_id"], family: a["family"]) }
      course.course_attributes = attributes

      course_json["sections"].map do |section_json|
        section = course.sections.build(section_json.slice("class_number", "number", "component", "credits_minimum", "credits_maximum", "location", "notes"))
        section.instruction_mode = InstructionMode.find_or_create_by(section_json["instruction_mode"].slice("instruction_mode_id","description"))
        section.grading_basis = GradingBasis.find_or_create_by(section_json["grading_basis"].slice("grading_basis_id","description"))

        section.grading_basis = GradingBasis.find_or_create_by(section_json["grading_basis"].slice("grading_basis_id","description"))
        section.save

        section_json["instructors"].each do |instructor_json|
          role = InstructorRole.find_or_create_by(abbreviation: instructor_json["role"])
          contact = InstructorContact.find_or_create_by(instructor_json.slice("name","email"))
          section.instructors.create(instructor_role: role, instructor_contact: contact)
        end

        section_json["meeting_patterns"].each do |pattern_json|
          mp = section.meeting_patterns.create(pattern_json.slice("start_time","end_time","start_date","end_date"))

          location_json = pattern_json["location"]
          if location_json
            mp.location = Location.find_or_create_by(location_json.slice("location_id","description"))
          end

          pattern_json["days"].each do |day|
            mp.days << Day.find_by_abbreviation(day["abbreviation"])
          end
          mp.save
        end

        section_json["combined_sections"].each do |cs_json|
          section.combined_sections.create(cs_json.slice("catalog_number", "subject_id", "section_number"))
        end
      end

      course.save
    end
  end

  private
  attr_accessor :json
end