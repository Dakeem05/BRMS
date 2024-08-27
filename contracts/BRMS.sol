// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.2 <= 0.9.0;

contract BRMS {
    struct Result {
        string course;
        uint score;
        string grade;
        uint semester;
        bool isVerified;
    }

    struct Student {
        address student;
        mapping (uint => mapping (string => Result)) results; // semester => course => Result
        string[] courses;
        uint[] semesters;
    }

    address public examsOfficer;
    address public university;
    mapping (address => Student) public students;
    mapping (address => string) public lecturers;

    event ResultUploaded(address student, uint semester, string course, uint score, string grade);

    modifier onlyExamsOfficer() {
        require(msg.sender == examsOfficer, "Not authorized");
        _;
    }

    modifier isValidLecturerAndCourse (address _address, string memory _course) {
        require((keccak256(abi.encodePacked(lecturers[_address])) == keccak256(abi.encodePacked(_course))), "Invalid lecturer or Course");
        _;
    }

    modifier onlyUniversity() {
        require(msg.sender == university, "Not authorized");
        _;
    }

    modifier scoreShouldBeLessThan100(uint _score) {
        require(_score < 100, "Score should be less than 100");
        _;
    }

    modifier isValidAddress(address _newExamsOfficer) {
        require(_newExamsOfficer != address(0), "Invalid address");
        _;
    }

    modifier isValidSemester(uint _semester) {
        require(_semester == 1 || _semester == 2, "Semester must be either first or second.");
        _;
    }

    constructor() {
        examsOfficer = msg.sender;
    }

    function uploadResult(
        address _student, 
        uint _score, 
        string memory _course, 
        uint _semester
    ) 
        public 
        isValidLecturerAndCourse(msg.sender, _course)
        scoreShouldBeLessThan100(_score) 
        isValidSemester(_semester)
    {
        
        string memory grade = _score >= 70 ? "A" : _score >= 60 ? "B" : _score >= 50 ? "C" : _score >= 45 ? "D" : _score >= 40 ? "E" : "F";
        Result memory studentResult = Result(_course, _score, grade, _semester, false);

        Student storage currentStudent = students[_student];
        currentStudent.student = _student;
        currentStudent.results[_semester][_course] = studentResult;

        // Add course and semester to the student's record if not already present
        bool courseExists = false;
        for (uint i = 0; i < currentStudent.courses.length; i++) {
            if (keccak256(bytes(currentStudent.courses[i])) == keccak256(bytes(_course))) {
                courseExists = true;
                break;
            }
        }
        if (!courseExists) {
            currentStudent.courses.push(_course);
            currentStudent.semesters.push(_semester);
        }

        emit ResultUploaded(_student, _semester, _course, _score, grade);
    }

    function verifyResult (address _student, string calldata _course, uint _semester) public isValidSemester(_semester) onlyExamsOfficer {
        Student storage student = students[_student];
        Result storage result = student.results[_semester][_course];
        result.isVerified = true;
    }

    function uploadLecturer (address _lecturer, string calldata _course) public isValidAddress(_lecturer) onlyExamsOfficer {
        lecturers[_lecturer] = _course;
    }

    function updateResult (address _student, string calldata _course, uint _score, uint _semester) public isValidSemester(_semester) onlyExamsOfficer scoreShouldBeLessThan100(_score) {
        Student storage student = students[_student];
        Result storage result = student.results[_semester][_course];
        string memory grade = _score >= 70 ? "A" : _score >= 60 ? "B" : _score >= 50 ? "C" : _score >= 45 ? "D" : _score >= 40 ? "E" : "F";
        result.grade = grade;
        result.score = _score;
    }

    function getAllResultsForUniversity(address _student) public view onlyUniversity returns (Result[] memory) {
        Student storage student = students[_student];

        require(student.student != address(0), "No results uploaded for this student.");

        uint resultCount = student.courses.length;

        Result[] memory results = new Result[](resultCount);
        uint counter = 0;

        for (uint i = 0; i < resultCount; i++) { 
            string memory course = student.courses[i];
            uint semester = student.semesters[i];
            if (student.results[semester][course].isVerified == false){
                break;
            }
            results[counter] = student.results[semester][course];
            counter++;
            
        }

        return results;
    }

    function getAllResultsForStudent() public view returns (Result[] memory) {
        Student storage student = students[msg.sender];
        require(student.student != address(0), "No results uploaded for this student.");
        uint resultCount = student.courses.length;

        Result[] memory results = new Result[](resultCount);
        uint counter = 0;

        for (uint i = 0; i < resultCount; i++) { 
            string memory course = student.courses[i];
            uint semester = student.semesters[i];
            if (student.results[semester][course].isVerified == false){
                break;
            }
            results[counter] = student.results[semester][course];
            counter++;
            
        }

        return results;
    }

    function getAllResultsForExamsOfficer(address _student) public view onlyExamsOfficer returns (Result[] memory) {
        Student storage student = students[_student];
        uint resultCount = student.courses.length;

        Result[] memory results = new Result[](resultCount);
        uint counter = 0;

        for (uint i = 0; i < resultCount; i++) { 
            string memory course = student.courses[i];
            uint semester = student.semesters[i];
            results[counter] = student.results[semester][course];
            counter++;
        }

        return results;
    }

    function updateUniversity(address _university) public isValidAddress(_university) onlyExamsOfficer {
        university = _university;
    }

    function changeExamsOfficer(address _newExamsOfficer) public isValidAddress(_newExamsOfficer) onlyExamsOfficer() {
        examsOfficer = _newExamsOfficer;
    }
}