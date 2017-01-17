module HomeHelper

  FIELD_NAME_MAP = {
    'notch' => 'Tab Width'
  }

  def field_name(field)
    FIELD_NAME_MAP[field] || field.to_s.capitalize
  end

  def config_form_element_group(keys = [], config = {}, label = true, tabindex_start = nil)
    keys.map do |field|
      config_form_element(config, field, label, tabindex_start)
    end.join('')
  end

  def config_form_element(config, field, label, tabindex_start)
    content_tag('p', class: 'form-label-and-element') do
      name    = "config[#{field}]"
      options = input_field_options(tabindex_start)

      label_tag(name, label ? field_name(field) : '') +
        number_field_tag(name, config[field], options)
    end
  end

  def input_field_options(tabindex_start)
    options = {
      min:      0.0,
      step:     0.01,
      class:    'numeric',
      tabindex: tabindex_start
    }
    options
  end
end
