module Views.Routines exposing (..)

import Array exposing (Array)
import Html exposing (..)
import Html.Attributes exposing (type', value, name, selected, checked)
import Html.Events exposing (onClick, onSubmit, onInput, onCheck)
import Html.Keyed as Keyed
import Messages exposing (..)
import Model exposing (Model)
import Models.Exercises exposing (Exercise, ExerciseId)
import Models.Routines exposing (Routine)
import Models.Sections exposing (Section, SectionExercise, SectionForm)
import Routing exposing (Route(..), reverse)
import String
import Utils exposing (onSelectInt, findById, textField, intField, navLink, htmlOrBlank)


{-| Render a listing of Routines.
-}
routinesPage : List Routine -> Html Msg
routinesPage routines =
    div []
        [ h1 [] [ text "Routines" ]
        , routineTable routines
        ]


{-| Render the details of a single `Routine`.
-}
routinePage : Model -> Routine -> Html Msg
routinePage model { id, name, copyright } =
    let
        sections =
            List.filter (\s -> s.routine == id) model.sections
    in
        div []
            [ h1 [] [ text name ]
            , button [ onClick <| NavigateTo <| RoutineEditRoute id ] [ text "Edit" ]
            , text " "
            , button [ onClick <| DeleteRoutineClicked id ] [ text "Delete" ]
            , p [] [ small [] [ text "Copyright: ", text copyright ] ]
            , div [] <|
                List.map (sectionTable model) sections
            ]


{-| Render a Routine's Section as a Table.
-}
sectionTable : Model -> Section -> Html Msg
sectionTable model { id, name } =
    let
        sectionExercises =
            List.filter (\se -> se.section == id) model.sectionExercises
    in
        div []
            [ h2 [] [ text name ]
            , table []
                [ thead []
                    [ th [] [ text "Exercise" ]
                    , th [] [ text "Volume" ]
                    ]
                , tbody [] <| List.map (sectionExerciseRow model) sectionExercises
                ]
            ]


{-| Render a Section's SectionExercise as a Table Row.
-}
sectionExerciseRow : Model -> SectionExercise -> Html Msg
sectionExerciseRow model sectionExercise =
    let
        selectedExercises =
            getSelectedExercises model.exercises sectionExercise.exercises

        ifSelected pred =
            htmlOrBlank <| List.any pred selectedExercises

        setRepTimeCounts =
            [ ( List.any (not << .isHold) selectedExercises, toString sectionExercise.repCount )
            , ( List.any .isHold selectedExercises, toString sectionExercise.holdTime ++ "s" )
            ]
                |> List.filter fst
                |> List.map (\( _, count ) -> toString sectionExercise.setCount ++ "x" ++ count)
                |> List.intersperse ", "
                |> String.concat

        exerciseLink exercise =
            navLink exercise.name <| ExerciseRoute exercise.id

        exerciseLinks =
            List.map exerciseLink selectedExercises
                |> List.intersperse (text " > ")
                |> span []
    in
        tr []
            [ td [] [ exerciseLinks ]
            , td [] [ text setRepTimeCounts ]
            ]


{-| Get the selected Exercises from the list of all Exercises.
-}
getSelectedExercises : List Exercise -> Array ExerciseId -> List Exercise
getSelectedExercises exercises ids =
    Array.foldr (\id list -> findById id exercises :: list) [] ids
        |> List.filterMap identity


{-| Render a table of Routines.
-}
routineTable : List Routine -> Html Msg
routineTable routines =
    table []
        [ thead []
            [ tr [] [ th [] [ text "Name" ] ] ]
        , tbody [] <| List.map routineRow routines
        ]


{-| Render a table row representing a Routine.
-}
routineRow : Routine -> Html Msg
routineRow { id, name } =
    tr [] [ td [] [ navLink name <| RoutineRoute id ] ]


{-| Render the form for creating an initial Routine before adding Exercises.
-}
addRoutineForm : Routine -> Html Msg
addRoutineForm routineForm =
    div []
        [ h1 [] [ text "Add Routine" ]
        , form [ onSubmit SubmitAddRoutineForm ]
            [ textField "Name" "name" routineForm.name (RoutineFormChange << RoutineNameChange)
            , p []
                [ input [ type' "submit", value "Save" ] []
                , text " "
                , button [ onClick CancelAddRoutineForm ] [ text "Cancel" ]
                ]
            ]
        ]


{-| Render the form for editing Routines & creating Sections/SectionExercises
-}
editRoutineForm : Model -> Html Msg
editRoutineForm { exercises, routineForm, sectionForms } =
    div []
        [ h1 [] [ text <| "Edit Routine - " ++ routineForm.name ]
        , textField "Routine Name" "name" routineForm.name (RoutineFormChange << RoutineNameChange)
        , br [] []
        , textField "Copyright" "copyright" routineForm.copyright (RoutineFormChange << RoutineCopyrightChange)
        , br [] []
        , label []
            [ text "Is Public: "
            , input
                [ type' "checkbox"
                , checked routineForm.isPublic
                , onCheck (RoutineFormChange << RoutinePublicChange)
                ]
                []
            ]
        , div [] <| Array.toList <| Array.indexedMap (editSectionForm exercises) sectionForms
        , p []
            [ button [ onClick (RoutineFormChange AddSection) ] [ text "Add Section" ]
            , text " "
            , button [ onClick SubmitEditRoutineForm ] [ text "Save Routine" ]
            , text " "
            , button [ onClick CancelEditRoutineForm ] [ text "Cancel" ]
            ]
        ]


{-| Render the form for editing a single `Section` of a `Routine`.
-}
editSectionForm : List Exercise -> Int -> SectionForm -> Html Msg
editSectionForm exercises index ({ section } as form) =
    let
        formMsg =
            RoutineFormChange << SectionFormMsg index

        sectionExerciseForms =
            Array.indexedMap (sectionExerciseForm exercises index) form.exercises
                |> Array.toList
                |> div []
    in
        fieldset []
            [ legend []
                [ text "Section: "
                , input
                    [ name "name"
                    , value section.name
                    , onInput <| formMsg << SectionNameChange
                    ]
                    []
                , text " "
                , button [ onClick <| RoutineFormChange <| MoveSectionUp index ]
                    [ text "↑" ]
                , button [ onClick <| RoutineFormChange <| MoveSectionDown index ]
                    [ text "↓" ]
                ]
            , sectionExerciseForms
            , div []
                [ button [ onClick <| formMsg <| AddSectionExercise ]
                    [ text "Add Exercise" ]
                , text " "
                , button [ onClick <| SaveSectionClicked index ] [ text "Save Section" ]
                , text " "
                , button [ onClick <| RoutineFormChange <| CancelSection index ]
                    [ text "Cancel" ]
                , text " "
                , if section.id /= 0 then
                    button [ onClick <| DeleteSectionClicked index section.id ]
                        [ text "Delete Section" ]
                  else
                    text ""
                ]
            ]


{-| Render the form for editing a single `SectionExercise` of a `Section`
-}
sectionExerciseForm : List Exercise -> Int -> Int -> SectionExercise -> Html Msg
sectionExerciseForm exercises sectionIndex exerciseIndex form =
    let
        sectionMsg =
            RoutineFormChange << SectionFormMsg sectionIndex

        formMsg =
            sectionMsg << SectionExerciseFormMsg exerciseIndex

        progressionCount =
            Array.length form.exercises

        progressionName =
            Array.get (progressionCount - 1) form.exercises
                `Maybe.andThen` (flip findById exercises)
                |> Maybe.map
                    (\{ name } ->
                        if progressionCount > 1 then
                            name ++ " Progression"
                        else
                            name
                    )
                |> Maybe.withDefault ""

        exerciseInputs =
            Array.toList <|
                Array.indexedMap
                    (editExerciseSelect exercises sectionIndex exerciseIndex)
                    form.exercises

        addExerciseInput =
            Keyed.node "div"
                []
                [ ( toString <| Array.length form.exercises
                  , addExerciseSelect exercises sectionIndex exerciseIndex
                  )
                ]

        selectedExercises =
            getSelectedExercises exercises form.exercises

        ifSelected pred =
            htmlOrBlank <| List.any pred selectedExercises

        repInput =
            ifSelected (not << .isHold) <|
                div []
                    [ intField "Reps" "reps" (toString form.repCount) <|
                        formMsg
                            << ChangeRepCount
                    , br [] []
                    , intField "Reps to Progress"
                        "progress-reps"
                        (toString form.repsToProgress)
                        (formMsg << ChangeRepProgress)
                    ]

        holdInput =
            ifSelected .isHold <|
                div []
                    [ intField "Hold Time" "hold-time" (toString form.holdTime) <|
                        formMsg
                            << ChangeHoldTime
                    , br [] []
                    , intField "Time to Progress"
                        "progress-time"
                        (toString form.timeToProgress)
                        (formMsg << ChangeHoldProgress)
                    ]
    in
        fieldset []
            [ legend []
                [ text <|
                    "Exercise #"
                        ++ toString (exerciseIndex + 1)
                        ++ " "
                        ++ progressionName
                , text " "
                , button [ onClick <| sectionMsg <| MoveExerciseUp exerciseIndex ]
                    [ text "↑" ]
                , button
                    [ onClick <| sectionMsg <| MoveExerciseDown exerciseIndex
                    ]
                    [ text "↓" ]
                ]
            , div [] exerciseInputs
            , addExerciseInput
            , intField "Sets" "sets" (toString form.setCount) <|
                formMsg
                    << ChangeSetCount
            , repInput
            , holdInput
            , div []
                [ button
                    [ onClick <| SaveSectionExerciseClicked sectionIndex exerciseIndex ]
                    [ text "Save Exercise" ]
                , text " "
                , button
                    [ onClick <| sectionMsg <| CancelSectionExercise exerciseIndex ]
                    [ text "Cancel" ]
                , text " "
                , if form.id /= 0 then
                    button
                        [ onClick <|
                            DeleteSectionExerciseClicked sectionIndex exerciseIndex form.id
                        ]
                        [ text "Delete Exercise" ]
                  else
                    text ""
                ]
            ]


{-| Render the select element for adding new `Exercises` to a `SectionExercise`.
-}
addExerciseSelect : List Exercise -> Int -> Int -> Html Msg
addExerciseSelect exercises sectionIndex exerciseIndex =
    select
        [ name "exercise"
        , onSelectInt <|
            RoutineFormChange
                << SectionFormMsg sectionIndex
                << SectionExerciseFormMsg exerciseIndex
                << AddExercise
        ]
    <|
        option [ selected True ] [ text "Add a Progression" ]
            :: List.map (exerciseOption Nothing) exercises


{-| Render the select element for editing the `Exercises` of a `SectionExercise`.
-}
editExerciseSelect : List Exercise -> Int -> Int -> Int -> ExerciseId -> Html Msg
editExerciseSelect exercises sectionIndex exerciseIndex index exerciseId =
    let
        formMsg =
            RoutineFormChange
                << SectionFormMsg sectionIndex
                << SectionExerciseFormMsg exerciseIndex
    in
        div []
            [ select
                [ name <| "exercise-" ++ toString index
                , onSelectInt <| formMsg << ChangeExercise index
                ]
              <|
                List.map (exerciseOption <| Just exerciseId) exercises
            , button [ onClick <| formMsg <| RemoveExercise index ]
                [ text "X" ]
            ]


{-| Render an option element for an `Exercise` select element.
-}
exerciseOption : Maybe ExerciseId -> Exercise -> Html Msg
exerciseOption maybeId exercise =
    option
        [ value <| toString exercise.id
        , selected (Maybe.map (\id -> id == exercise.id) maybeId |> Maybe.withDefault False)
        ]
        [ text exercise.name ]
