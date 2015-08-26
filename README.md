# Employee hiring optimization solution

This repository contains a solution to an employee hiring optimization problem using Constraint Logic Programming, developed on the "Logic Programming" course at FEUP. The development plataform used was Sicstus Prolog 4.3.0, along with the "clpfd" library for Constraint Logic Programming in Prolog.

This project was developed by [JPMMaia](https://github.com/JPMMaia) and [msandim](https://github.com/msandim).

For further information on the topics of this project, check the [report](https://github.com/msandim/optimization-employment-plog/raw/master/resources/report.pdf) (portuguese only).

## 1. Problem description

The problem being addressed in this solution relates to employee hiring: an imaginary company needs several employees during a work day, which can be of two types:
* Fulltime employees: work all day, with 1 free luch hour. May work on their lunch hour for a bonus;
* Part-time employees: work 3 hours, with no lunch hour May work an extra hour for a bonus.

The number of employees working in their lunch hour or working extra hours are limited by the Workers Union. The number of part-time employees is limited by number and ratio when compared to the number of fulltime employees.

**An optimal solution to this problem is the employee configuration that costs less (in terms of salaries to pay) to the company.**

## 2. Command line interface



![gui](https://github.com/msandim/optimization-employment-plog/raw/master/resources/solution.png)

After launching the configuration, information regarding the schedule of each employee is showed (textually and graphically), along with the timetable.
