

class SchedulingController < ApplicationController

  def show
    @days_of_week = weekdays(1)
    @days_of_week2 = weekdays(2)
    #submitedHour = SubmitedHour.where(:week_start_date =>  getStartDate)
    #createHash(submitedHour)
    submitedHour = SubmitedHour.where(:week_start_date =>  @days_of_week[0])
    createHash(submitedHour)
    if(request.post?)
      save_to_db
    end

	
    #submitedHour = SubmitedHour.where(:week_start_date =>  getStartDate)
    #  createHash(submitedHour)
    #if(request.post?)
    # save_to_db
    #end
    if alreadyExistRecords?
      loadFromDB
    end
  end

  def save_to_db
    @array = Array.new
    params.each do |par|
      if day_param?(par[0])
          @array.push par[0]
      end
    end
    proccess_shifts(@array)

    flash[:notice] = "Schedule table was successfully updated."
    redirect_to scheduling_path
  end

  private

  def createHash(submited_array)

    @shiftMap = Hash.new

    ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'].each do |day_name|
      create_array day_name, @shiftMap
    end


    if submited_array.kind_of? SubmitedHour
      ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'].each do |day_name|
        create_events submited_array, day_name, @shiftMap
      end
    else
      submited_array.each do |submit|
        ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'].each do |day_name|
          create_events submit, day_name, @shiftMap
        end
      end

    end


  end

  def create_array(day, shifts_map)
    shifts_map[day+'_morning']   = Array.new
    shifts_map[day+'_evening']   = Array.new
    shifts_map[day+'_night']     = Array.new
  end

  def create_events(record, day_name, hash_map )    #TODO move user to called method?
    user = User.find(record.user_id)
    if record.method(:"#{day_name}_morning").call == true
      hash_map[ day_name + '_morning' ] << [(user.name.nil? ? '':user.name) + ' ' + (user.l_name.nil? ? '':user.l_name), false , user.id ]
    end

    if record.method(:"#{day_name}_evening").call == true
      hash_map[ day_name + '_evening' ] << [(user.name.nil? ? '':user.name) + ' ' + (user.l_name.nil? ? '':user.l_name), false , user.id ]
    end

    if record.method(:"#{day_name}_night").call == true
      hash_map[ day_name + '_night' ] << [(user.name.nil? ? '':user.name) + ' ' + (user.l_name.nil? ? '':user.l_name), false , user.id ]
    end

  end

  def getStartDate
    Date.parse('22-06-2014')
  end

  def weekdays(week)
    t = Time.now
    t +=   (60*60*24*7) if week == 2
    ans = Hash.new
    temp_t = t.wday
    while temp_t != 0
      t -= (60*60*24)
      temp_t = t.wday
    end
    7.times do
      ans[t.wday] = t.strftime("%d/%m/%Y")
      t += (60*60*24)
    end
    ans
  end

  def day_param?(str)
    ans = str =~ /\A(Sun|Mon|Tues|Wed|Thu|Frid|Sat).+/
    ans != nil
  end

  def proccess_shifts(arr)
    startDate = getStartDate
    Shifts.where(:week_number => @days_of_week[0]).destroy_all
    arr.each do |temp|
      shift_info = temp.split('_')
      day = shift_info[0].to_s
      time = shift_info[1].to_s
      worker = shift_info[4].to_i
      #Shifts.create(:name => day + '_' + time, :worker => worker)
      new_shift = Shifts.create!
      new_shift.week_number = @days_of_week[0]
      new_shift.shift_name = day+'_'+time
      new_shift.user_id = worker
      new_shift.save!
    end

  end

  def alreadyExistRecords?
    Shifts.where(:week_number => @days_of_week[0]) != nil
  end

  def loadFromDB
    #@shiftMap = Hash.new
    allshifts = Shifts.where(:week_number => @days_of_week[0])
    if allshifts == nil
      return
    end

    allshifts.each do |shift|
      arr = @shiftMap["#{shift.shift_name}"]
        arr.each do |tempArr|
          if(tempArr[2] == shift.user_id)
            tempArr[1] = true
          end
        end
    end
  end

end
