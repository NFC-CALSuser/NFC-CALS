# Define API endpoints
$attendanceUrl = "https://cals-server-12aff9883ee5.herokuapp.com/attendance"
$instructorViewUrl = "https://cals-server-12aff9883ee5.herokuapp.com/instructor_view"
$studentsViewUrl = "https://cals-server-12aff9883ee5.herokuapp.com/students_view"

# Get session ID from parameter or use latest
$sessionId = $args[0]

# First, get all the data we need
try {
    $attendanceData = Invoke-RestMethod -Uri $attendanceUrl -Method Get
    $instructorViewData = Invoke-RestMethod -Uri $instructorViewUrl -Method Get
    $studentsViewData = Invoke-RestMethod -Uri $studentsViewUrl -Method Get
}
catch {
    Write-Error "Error getting data: $_"
    exit
}

# Get the session to process
if ($sessionId) {
    $sessionToProcess = $attendanceData | Where-Object { $_.id -eq $sessionId }
} else {
    # Get most recent active session
    $sessionToProcess = $attendanceData | 
        Where-Object { $_.status -ne 'ended' } |
        Sort-Object -Property date -Descending | 
        Select-Object -First 1
}

if (-not $sessionToProcess) {
    Write-Error "No active session found"
    exit
}

Write-Output "Processing attendance record from: $($sessionToProcess.date)"

$courseId = $sessionToProcess.course_id
$instructorId = $sessionToProcess.instructor_id
$presentStudents = $sessionToProcess.students_ids
$attendanceDate = ($sessionToProcess.date -split " ")[0]  # Extract just the date part
$formattedDate = [DateTime]::ParseExact($attendanceDate, "yyyy-MM-dd", $null).ToString("dd-MM-yyyy")

Write-Output "Course: $courseId, Instructor: $instructorId"
Write-Output "Present students: $($presentStudents -join ', ')"
Write-Output "Attendance date (formatted): $formattedDate"

# Create copies of data to modify
$updatedInstructorData = $instructorViewData | ConvertTo-Json -Depth 10 | ConvertFrom-Json
$updatedStudentsData = $studentsViewData | ConvertTo-Json -Depth 10 | ConvertFrom-Json

# Validate data
if (-not $updatedInstructorData.$instructorId -or 
    -not $updatedInstructorData.$instructorId.courses.$courseId) {
    Write-Error "Instructor or course not found in instructor view"
    exit
}

# Get enrolled students
$enrolledStudents = $updatedInstructorData.$instructorId.courses.$courseId.students.PSObject.Properties.Name
Write-Output "Enrolled students: $($enrolledStudents -join ', ')"

$absentStudents = @()

# Update instructor_view
foreach ($studentId in $enrolledStudents) {
    if ($presentStudents -contains $studentId) {
        Write-Output "Student $studentId was present"
        continue
    }
    
    $student = $updatedInstructorData.$instructorId.courses.$courseId.students.$studentId
    
    # Update percentage
    $currentPercentage = [int]($student.current_percentage -replace '%', '')
    $newPercentage = $currentPercentage + 3
    $student.current_percentage = "$newPercentage%"
    
    # Add absence date
    if ($null -eq $student.absence_dates) {
        $student.absence_dates = @($formattedDate)
    } else {
        if ($student.absence_dates -notcontains $formattedDate) {
            $student.absence_dates += $formattedDate
        }
    }
    
    $absentStudents += $studentId
    Write-Output "Marked student $studentId absent in instructor view"
}

# Update students_view
foreach ($student in $updatedStudentsData.read_only) {
    if ($absentStudents -notcontains $student.student_id) {
        continue
    }
    
    foreach ($course in $student.courses) {
        if ($course.course -eq $courseId) {
            $currentPercentage = [int]($course.current_percentage -replace '%', '')
            $newPercentage = $currentPercentage + 3
            $course.current_percentage = "$newPercentage%"
            
            if ($null -eq $course.absence_dates) {
                $course.absence_dates = @($formattedDate)
            } else {
                if ($course.absence_dates -notcontains $formattedDate) {
                    $course.absence_dates += $formattedDate
                }
            }
            
            Write-Output "Marked student $($student.student_id) absent in students view"
            break
        }
    }
}

# Mark session as ended
$headers = @{ "Content-Type" = "application/json" }

# End the session first
try {
    $endSessionBody = @{
        status = "ended"
        students_ids = $presentStudents
    } | ConvertTo-Json
    
    $endResult = Invoke-RestMethod -Uri "$attendanceUrl/$($sessionToProcess.id)" -Method Patch -Body $endSessionBody -Headers $headers
    Write-Output "Successfully ended session"
}
catch {
    Write-Error "Error ending session: $_"
    exit
}

# Update instructor view
try {
    $instructorBody = $updatedInstructorData | ConvertTo-Json -Depth 10
    $updateResult = Invoke-RestMethod -Uri $instructorViewUrl -Method Put -Body $instructorBody -Headers $headers
    Write-Output "Successfully updated instructor view"
}
catch {
    Write-Error "Error updating instructor view: $_"
}

# Update students view
try {
    $studentsBody = $updatedStudentsData | ConvertTo-Json -Depth 10
    $updateResult = Invoke-RestMethod -Uri $studentsViewUrl -Method Put -Body $studentsBody -Headers $headers
    Write-Output "Successfully updated students view"
}
catch {
    Write-Error "Error updating students view: $_"
}

# Summary
Write-Output "`nSummary:"
Write-Output "Total enrolled students: $($enrolledStudents.Count)"
Write-Output "Present students: $($presentStudents.Count) - $($presentStudents -join ', ')"
Write-Output "Absent students: $($absentStudents.Count) - $($absentStudents -join ', ')"
