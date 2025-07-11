#!/usr/bin/env python3
import json
import sys
import random
from collections import defaultdict
from itertools import cycle

class ScheduleGenerator:
    def __init__(self, students, teachers):
        self.students = students
        self.teachers = teachers
        self.TIME_SLOTS = ["16h40 - 18h", "17h40 - 19h", "18h40 - 20h"]
        self.NUM_SESSIONS = 10
        self.MAX_TEACHER_GROUPS = 3
        self.group_history = {}  # key = frozenset of student names, value = list of assigned teachers

    def group_students(self):
        """Group students into small groups of 2-3"""
        boarding = [s for s in self.students if s["type"] == "Boarding"]
        day = [s for s in self.students if s["type"] == "Day"]

        def make_groups(sublist):
            random.shuffle(sublist)
            result = []
            i = 0
            while i < len(sublist):
                size = random.choice([2, 3])
                group = sublist[i:i + size]
                if len(group) >= 2:
                    result.append(group)
                    i += size
                else:
                    if result:  # If there are previous groups, merge with last group
                        result[-1].extend(group)
                    else:  # If this is the only group but too small, keep it as is
                        result.append(group)
                    break
            return result

        return make_groups(boarding) + make_groups(day)

    def get_group_key(self, group):
        """Create a unique key for a group based on student names"""
        return frozenset(s["name"] for s in group)

    def choose_teacher_for_group(self, group_key, teacher_loads):
        """Choose the best teacher for a group, considering history and current load"""
        previous_teachers = self.group_history.get(group_key, [])
        
        # Sort teachers by: 1) not previously used with this group, 2) current load
        available = sorted(
            self.teachers, 
            key=lambda t: (t in previous_teachers, teacher_loads[t])
        )
        
        for teacher in available:
            if teacher_loads[teacher] < self.MAX_TEACHER_GROUPS:
                return teacher
        return None

    def assign_groups(self, groups):
        """Assign groups to teachers"""
        assignments = defaultdict(list)
        teacher_loads = {t: 0 for t in self.teachers}

        # Sort groups to prioritize boarding students (they have less flexibility)
        sorted_groups = sorted(
            groups, 
            key=lambda g: any(s["type"] == "Boarding" for s in g), 
            reverse=True
        )

        for group in sorted_groups:
            group_key = self.get_group_key(group)
            teacher = self.choose_teacher_for_group(group_key, teacher_loads)

            if teacher:
                assignments[teacher].append(group)
                teacher_loads[teacher] += 1
                
                # Update history
                if group_key not in self.group_history:
                    self.group_history[group_key] = []
                self.group_history[group_key].append(teacher)
            else:
                raise Exception("Could not assign teacher due to overload")

        return assignments

    def adjust_last_group(self, assignments):
        """Adjust assignments to ensure boarding students don't get the last time slot when possible"""
        for teacher, group_list in assignments.items():
            if len(group_list) == 3:  # Teacher has 3 groups
                last_group = group_list[2]
                # If last group has boarding students, try to swap with a day-only group
                if any(s["type"] == "Boarding" for s in last_group):
                    for t2, other_list in assignments.items():
                        for i in range(min(2, len(other_list))):  # Check first 2 time slots
                            if all(s["type"] == "Day" for s in other_list[i]):
                                # Swap the groups
                                group_list[2], other_list[i] = other_list[i], group_list[2]
                                return

    def format_table(self, assignments, session_number):
        """Format the assignments into a table structure"""
        table = [["Prep"] + self.teachers]
        
        for i, slot in enumerate(self.TIME_SLOTS):
            row = [slot]
            for teacher in self.teachers:
                if teacher in assignments and len(assignments[teacher]) > i:
                    group = assignments[teacher][i]
                    row.append(", ".join(s["name"] for s in group))
                else:
                    row.append("")
            table.append(row)
        
        table.append(["Date"] + [f"Session {session_number + 1}"] * len(self.teachers))
        return table

    def generate_sessions(self):
        """Generate all 10 sessions"""
        sessions = []
        
        for session in range(self.NUM_SESSIONS):
            try:
                groups = self.group_students()
                assignments = self.assign_groups(groups)
                self.adjust_last_group(assignments)
                table = self.format_table(assignments, session)
                
                sessions.append({
                    "session_number": session + 1,
                    "table": table
                })
                
            except Exception as e:
                sessions.append({
                    "session_number": session + 1,
                    "error": str(e)
                })
        
        return sessions

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 schedule_generator.py <input_file> <output_file>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    try:
        # Read input data
        with open(input_file, 'r') as f:
            input_data = json.load(f)
        
        teachers = input_data['teachers']
        students = input_data['students']
        
        # Validate input
        if not teachers or len(teachers) < 1 or len(teachers) > 5:
            raise ValueError("Number of teachers must be between 1 and 5")
        
        if not students or len(students) < 15 or len(students) > 25:
            raise ValueError("Number of students must be between 15 and 25")
        
        # Generate schedule
        generator = ScheduleGenerator(students, teachers)
        sessions = generator.generate_sessions()
        
        # Write output
        output_data = {
            "success": True,
            "sessions": sessions
        }
        
        with open(output_file, 'w') as f:
            json.dump(output_data, f, indent=2)
            
    except Exception as e:
        # Write error output
        output_data = {
            "success": False,
            "error": str(e)
        }
        
        with open(output_file, 'w') as f:
            json.dump(output_data, f, indent=2)
        
        sys.exit(1)

if __name__ == "__main__":
    main()