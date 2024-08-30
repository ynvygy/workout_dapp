module basic_address::workout_dapp {
    //use std::table;
    use std::signer;
    //use std::random;
    use std::vector;
    use std::debug;
    use std::string::{String,utf8};
    use aptos_framework::randomness;

    struct ExercisesList has key {
        exercises: vector<Exercise>,
    }

    struct Exercise has copy, store, drop {
        name: vector<u8>,
    }

    struct Profile has key, copy {
        exercises_completed: vector<ProfileExercise>,
        total_workouts: u64,
    }

    struct ProfileExercise has store, copy, drop {
        name: vector<u8>,
        total_workouts: u64,
    }

    struct Levels has key, store {
        level: u64,
        level_limit: u64
    }

    fun init_module(account: &signer) {
        let profile = Profile {
          exercises_completed: vector::empty<ProfileExercise>(),
          total_workouts: 0,
        };
        move_to(account, profile);

        let exercises = vector::empty<Exercise>();
        vector::push_back(&mut exercises, Exercise { name: b"Chest" });
        vector::push_back(&mut exercises, Exercise { name: b"Back" });
        vector::push_back(&mut exercises, Exercise { name: b"Shoulders" });
        vector::push_back(&mut exercises, Exercise { name: b"Legs" });
        vector::push_back(&mut exercises, Exercise { name: b"Arms" });
        vector::push_back(&mut exercises, Exercise { name: b"Core" });
        vector::push_back(&mut exercises, Exercise { name: b"Biceps" });

        let list = ExercisesList { exercises };
        move_to(account, list);
    }

    public entry fun start_exercise(account: &signer, resource_address: address, index: u64) acquires ExercisesList, Profile {
        let account_address = signer::address_of(account);
        let repository = borrow_global<ExercisesList>(resource_address);
        let exercise = *vector::borrow(&repository.exercises, index);

        if (exists<Profile>(account_address)) {
            let profile = borrow_global_mut<Profile>(account_address);
            profile.total_workouts = profile.total_workouts + 1;

            let length = vector::length(&profile.exercises_completed);
            let exercise_exists = false;
            let i = 0;

            while (i < length) {
                let existing_exercise = vector::borrow_mut(&mut profile.exercises_completed, i);
                if (&exercise.name == &existing_exercise.name) {
                    exercise_exists = true;
                    existing_exercise.total_workouts = existing_exercise.total_workouts + 1;
                    break
                };
                i = i + 1;
            };
            if (exercise_exists == false) {
                let new_exercise = ProfileExercise {
                    name: exercise.name,
                    total_workouts: 1,
                };
                vector::push_back(&mut profile.exercises_completed, new_exercise);
            }

        } else {
            let new_exercise = ProfileExercise {
                name: exercise.name,
                total_workouts: 1,
            };

            let profile = Profile {
              exercises_completed: vector::empty<ProfileExercise>(),
              total_workouts: 1,
            };
            vector::push_back(&mut profile.exercises_completed, new_exercise);
            move_to(account, profile);
        };
    }

    public entry fun add_exercise(account: &signer, name: vector<u8>) acquires ExercisesList {
        let account_address = signer::address_of(account);
        let repository = borrow_global_mut<ExercisesList>(account_address);
        let exercise = Exercise { name };

        vector::push_back(&mut repository.exercises, exercise);
    }

    public entry fun remove_exercise(account: &signer, name: vector<u8>) acquires ExercisesList {
        let account_address = signer::address_of(account);
        let repository = borrow_global_mut<ExercisesList>(account_address);
        let length = vector::length(&repository.exercises);

        let i = 0;
        while (i < length) {
            let exercise = vector::borrow(&repository.exercises, i);
            if (&exercise.name == &name) {
                vector::remove(&mut repository.exercises, i);
                break
            };
            i = i + 1;
        };
    }

    #[view]
    public fun get_top_3_exercises(account: address): vector<ProfileExercise> acquires Profile {
        let profile = borrow_global<Profile>(account);
        let exercises = &profile.exercises_completed;

        let sorted_exercises: vector<ProfileExercise> = vector::empty<ProfileExercise>();
        let length = vector::length(exercises);
        let i = 0;
        while (i < length) {
            let exercise = *vector::borrow(exercises, i);
            sorted_exercises = sorted_exercises;
            let inserted = false;
            let j = 0;
            while (j < vector::length(&sorted_exercises)) {
                let sorted_exercise = *vector::borrow(&sorted_exercises, j);
                if (exercise.total_workouts > sorted_exercise.total_workouts) {
                    vector::insert(&mut sorted_exercises, j, exercise);
                    break
                } else {
                    j = j + 1;
                }
            };
            if (!inserted && j == vector::length(&sorted_exercises)) {
                vector::push_back(&mut sorted_exercises, exercise);
            };
            i = i + 1;
        };

        let top_3_exercises: vector<ProfileExercise> = vector::empty<ProfileExercise>();
        let i = 0;
        while (i < 3 && i < vector::length(&sorted_exercises)) {
            let exercise = *vector::borrow(&sorted_exercises, i);
            vector::push_back(&mut top_3_exercises, exercise);
            i = i + 1;
        };
        top_3_exercises
    }

    #[view]
    public fun get_profile_exercise(account: address, index: u64): ProfileExercise acquires Profile {
        let profile = borrow_global<Profile>(account);
        let exercise = *vector::borrow(&profile.exercises_completed, index);
        exercise
    }

    #[view]
    public fun get_exercises_list_count(account: address): u64 acquires ExercisesList {
        let repository = borrow_global<ExercisesList>(account);
        vector::length(&repository.exercises)
    }

    #[view]
    public fun get_exercise_name_by_index(account: address, index: u64): vector<u8> acquires ExercisesList {
        let repository = borrow_global<ExercisesList>(account);
        let exercise = vector::borrow(&repository.exercises, index);
        exercise.name
    }

    #[view]
    #[lint::allow_unsafe_randomness]
    public fun get_seven_exercises(account: address): vector<Exercise> acquires ExercisesList {
        let repository = borrow_global<ExercisesList>(account);
        let exercises: vector<Exercise> = vector::empty<Exercise>();
        let i = 0;
        while (i < 7) {
            let index = get_random_number(6-i);
            let exercise = *vector::borrow(&repository.exercises, index);
            vector::push_back(&mut exercises, exercise);
            i = i + 1;
        };
        exercises
    }

    #[view]
    public fun get_exercise(account: address, index: u64): Exercise acquires ExercisesList {
        let repository = borrow_global<ExercisesList>(account);
        let exercise = *vector::borrow(&repository.exercises, index);
        exercise
    }

    #[view]
    #[lint::allow_unsafe_randomness]
    public fun get_random_exercise(account: address): vector<u8> acquires ExercisesList {
        let repository = borrow_global<ExercisesList>(account);
        let len = vector::length(&repository.exercises);

        let index = get_random_number(len);

        let exercise = vector::borrow(&repository.exercises, index);
        exercise.name
    }

    fun get_random_number(length: u64): u64 {
        randomness::u64_range(0, length)
    }

    #[test(account = @0x1)]
    public fun test_init(account: signer) {
        init_module(&account);
        let account_address = signer::address_of(&account);
        assert!(exists<Profile>(account_address), 1);
        assert!(exists<ExercisesList>(account_address), 1);
    }

    #[test(account = @0x1)]
    public fun test_length(account: signer) acquires ExercisesList {
        init_module(&account);
        let account_address = signer::address_of(&account);
        let exercises = get_exercises_list_count(account_address);
        assert!(exercises == 7, 1);

        let name = get_exercise_name_by_index(account_address, 2);
        let shoulders = b"Shoulders";
        assert!(name == shoulders, 2);
    }

    #[test(account = @0x1)]
    public fun test_adding_an_exercise(account: signer) acquires ExercisesList {
        init_module(&account);
        let name = b"Test Exercise";
        add_exercise(&account, name);

        let account_address = signer::address_of(&account);
        let exercises = get_exercises_list_count(account_address);
        assert!(exercises == 8, 1);

        let exercise = get_exercise(account_address, 7);
        assert!(exercise.name == name, 1);
    }

    #[test(account = @0x1)]
    public fun test_removing_an_exercise(account: signer) acquires ExercisesList {
        init_module(&account);
        let name = b"Legs";
        remove_exercise(&account, name);

        let account_address = signer::address_of(&account);
        let exercises = get_exercises_list_count(account_address);
        assert!(exercises == 6, 1);

        remove_exercise(&account, name);
        let exercises = get_exercises_list_count(account_address);
        assert!(exercises == 6, 1);

        let exercise = get_exercise(account_address, 3);
        assert!(exercise.name == b"Arms", 1);
    }

    #[test(account = @0x1, account_two = @0x2)]
    public fun test_start_exercise(account: signer, account_two: signer) acquires Profile, ExercisesList {
        init_module(&account);
        let owner_address = signer::address_of(&account);
        start_exercise(&account_two, owner_address, 1);
        let account_address = signer::address_of(&account_two);

        let profile = borrow_global<Profile>(account_address);
        let exercises = profile.exercises_completed;
        assert!(vector::length(&exercises) == 1, 1);

        let owner_address = signer::address_of(&account);
        start_exercise(&account_two, owner_address, 1);
        let profile = borrow_global<Profile>(account_address);
        let new_exercises = profile.exercises_completed;
        assert!(vector::length(&new_exercises) == 1, 1);

        let exercise = get_profile_exercise(account_address, 0);
        assert!(exercise.name == b"Back", 1);
    }

    #[test(account = @0x1)]
    public fun test_get_top_3_exercises(account: signer) acquires Profile, ExercisesList {
        init_module(&account);
        let owner_address = signer::address_of(&account);
        start_exercise(&account, owner_address, 1);
        start_exercise(&account, owner_address, 2);
        start_exercise(&account, owner_address, 3);
        start_exercise(&account, owner_address, 3);

        let top_exercises = get_top_3_exercises(owner_address);
        assert!(vector::length(&top_exercises) == 3, 1);

        let top_exercise = *vector::borrow(&top_exercises, 0);
        assert!(top_exercise.name == b"Legs", 1);
    }

}
