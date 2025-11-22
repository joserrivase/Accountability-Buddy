# Goal Questionnaire System - Update Guide

## Overview

The goal questionnaire system is a dynamic, decision-tree-based flow that guides users through creating goals. The system is designed to be **extremely easy to update** in the future.

## Architecture

### Key Components

1. **Models** (`Models/GoalQuestionnaire.swift`)
   - `QuestionID`: Enum of all question identifiers
   - `QuestionType`: Enum of question input types
   - `Question`: Struct representing a question
   - `GoalQuestionnaireAnswers`: Struct storing all user answers

2. **Flow Engine** (`ViewModels/GoalQuestionnaireFlowEngine.swift`)
   - `GoalQuestionnaireFlowEngine`: ObservableObject that manages the flow
   - Contains all question definitions
   - Contains decision tree logic in `getNextQuestion()`

3. **Views**
   - `GoalQuestionnaireView.swift`: Main questionnaire container
   - `QuestionViews.swift`: Individual question type views
   - `GoalReviewView.swift`: Final review and creation screen

## How to Update the Question Tree

### Step 1: Add a New Question ID

In `Models/GoalQuestionnaire.swift`, add a new case to the `QuestionID` enum:

```swift
enum QuestionID: String, Codable {
    // ... existing cases
    case myNewQuestion = "my_new_question"
}
```

### Step 2: Define the Question

In `ViewModels/GoalQuestionnaireFlowEngine.swift`, add your question to the `allQuestions` dictionary:

```swift
private let allQuestions: [QuestionID: Question] = [
    // ... existing questions
    
    .myNewQuestion: Question(
        id: .myNewQuestion,
        type: .textInput, // or .multipleChoice, .yesNo, etc.
        title: "What is your question?",
        description: "Optional description text",
        placeholder: "Optional placeholder",
        options: nil, // Required for .multipleChoice
        validation: ValidationRule(isRequired: true)
    )
]
```

### Step 3: Add Flow Logic

In `GoalQuestionnaireFlowEngine.swift`, update the `getNextQuestion()` method to include your new question in the decision tree:

```swift
func getNextQuestion() -> QuestionID? {
    guard let currentID = currentQuestionID else {
        return .goalName
    }
    
    switch currentID {
    // ... existing cases
    
    case .somePreviousQuestion:
        // Add logic to determine when to show your new question
        if someCondition {
            return .myNewQuestion
        } else {
            return .someOtherQuestion
        }
        
    case .myNewQuestion:
        // Determine what comes after your question
        return .nextQuestionID
        
    // ... rest of cases
    }
}
```

### Step 4: Handle Answer Storage

In `GoalQuestionnaireView.swift`, update the `handleAnswer()` method to save the answer:

```swift
private func handleAnswer() {
    guard let question = flowEngine.getCurrentQuestion() else { return }
    
    switch question.id {
    // ... existing cases
    
    case .myNewQuestion:
        if let text = currentAnswer as? String {
            flowEngine.answers.myNewAnswer = text
        }
        
    // ... rest of cases
    }
    
    flowEngine.moveToNext()
    currentAnswer = nil
}
```

Also add the property to `GoalQuestionnaireAnswers` in `Models/GoalQuestionnaire.swift`:

```swift
struct GoalQuestionnaireAnswers {
    // ... existing properties
    var myNewAnswer: String?
}
```

### Step 5: Create Question View (if needed)

If you're using a new question type, create a view in `QuestionViews.swift`:

```swift
struct MyNewQuestionView: View {
    let question: Question
    @Binding var answer: Any?
    
    var body: some View {
        // Your custom UI here
    }
}
```

Then add it to `QuestionContentView` in `GoalQuestionnaireView.swift`:

```swift
switch question.type {
// ... existing cases
case .myNewType:
    MyNewQuestionView(question: question, answer: $answer)
}
```

## Example: Adding a New Branch

Let's say you want to add a question that only appears for "List Tracker" goals when the user selects "Challenge" mode:

1. **Add Question ID:**
```swift
case .newChallengeQuestion = "new_challenge_question"
```

2. **Define Question:**
```swift
.newChallengeQuestion: Question(
    id: .newChallengeQuestion,
    type: .multipleChoice,
    title: "What challenge level?",
    options: [
        QuestionOption(id: "easy", title: "Easy"),
        QuestionOption(id: "hard", title: "Hard")
    ]
)
```

3. **Add Flow Logic:**
```swift
case .challengeOrFriendly:
    if answers.isChallenge {
        // Check if it's a list tracker
        if answers.goalType == "list_tracker" {
            return .newChallengeQuestion
        }
        return .winningCondition
    } else {
        return nil
    }

case .newChallengeQuestion:
    return .winningCondition
```

4. **Handle Answer:**
```swift
case .newChallengeQuestion:
    if let optionId = currentAnswer as? String {
        flowEngine.answers.challengeLevel = optionId
    }
```

5. **Add to Answers Struct:**
```swift
var challengeLevel: String?
```

## Dynamic Options

For questions with dynamic options (like winning conditions), use the `getWinningConditionOptions()` pattern:

1. In `GoalQuestionnaireFlowEngine`, create a method that returns options based on current answers:
```swift
func getMyDynamicOptions() -> [QuestionOption] {
    var options: [QuestionOption] = []
    
    // Build options based on answers.goalType, answers.someOtherAnswer, etc.
    if answers.goalType == "list_tracker" {
        options.append(QuestionOption(id: "option1", title: "Option 1"))
    }
    
    return options
}
```

2. In `MultipleChoiceQuestionView`, check for the question ID and use dynamic options:
```swift
var options: [QuestionOption] {
    if question.id == .myDynamicQuestion {
        return flowEngine.getMyDynamicOptions()
    } else {
        return question.options ?? []
    }
}
```

## Best Practices

1. **Keep Questions Modular**: Each question should be independent and reusable
2. **Use Descriptive IDs**: Question IDs should clearly indicate what they're asking
3. **Validate Early**: Add validation rules to questions to catch errors early
4. **Comment Your Logic**: Add comments explaining why certain branches exist
5. **Test All Paths**: When adding new branches, test all possible paths through the tree

## Common Question Types

- **`.textInput`**: Free text entry
- **`.multipleChoice`**: Select one from multiple options
- **`.yesNo`**: Simple yes/no choice
- **`.buddySelection`**: Select a friend or go solo
- **`.listInput`**: Create a list of items
- **`.numberInput`**: Enter a number
- **`.dateInput`**: Select a date
- **`.unitSelection`**: Select a unit (with custom option)

## Testing Your Changes

1. Start the questionnaire from the beginning
2. Follow each branch of the decision tree
3. Verify answers are saved correctly
4. Check that the review screen displays all answers
5. Ensure goal creation works with new answers

## Need Help?

If you need to add complex branching logic:
1. Review the existing `getNextQuestion()` method
2. Look at how `winningCondition` questions are handled dynamically
3. Check how `daily_tracker` questions branch based on previous answers

The system is designed to be flexible - you can add questions, remove questions, or completely restructure the flow by modifying the `getNextQuestion()` method.

