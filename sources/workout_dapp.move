module basic_address::workout_dapp {
    //use std::table;
    use std::signer;
    //use aptos_framework::randomness;
    use std::vector;
    //use std::debug;
    use std::string::{utf8};
    use aptos_framework::event;
    use std::option;
    use aptos_token_objects::collection::{Self};
    use aptos_framework::object;
    use aptos_token_objects::token::{Self, Token};

    const DOES_NOT_EXIST: u64 = 1;
    const INCORRECT_ITEM: u64 = 2;
    const INCORRECT_COUNT: u64 = 3;
    const INCORRECT_LENGTH: u64 = 4;
    const VECTOR_OPERATION_ERROR: u64 = 1001; // Custom error code for vector operation

    const WORKOUT_COLLECTION_NAME: vector<u8> = b"Workouts";
    const WORKOUT_COLLECTION_DESCRIPTION: vector<u8> = b"Workout NFTs";
    const WORKOUT_COLLECTION_URI: vector<u8> = b"no.website.com";

    const DEPLOYER: address = @0xee8c9c1ef146cf41a3000605b09f5127333eb14ee78c881e6652c9f4f06cdf70;

    struct ExercisesList has key {
        exercises: vector<Exercise>,
    }

    struct Exercise has copy, store, drop {
        name: vector<u8>,
    }

    struct Profile has key {
        exercises_completed: vector<ProfileExercise>,
        total_workouts: u64,
        last_random_exercise: u64,
        delete_ref: object::DeleteRef,
    }

    struct ProfileExercise has store, copy, drop {
        name: vector<u8>,
        total_workouts: u64,
    }

    struct Levels has key, store {
        level: u64,
        level_limit: u64
    }

    #[event]
    struct ProfileCreated has drop, store {
        new_profile_address: address,
    }

    #[event]
    struct ProfileExerciseAdded has drop, store {
        profile_address: address,
        exercise_name: vector<u8>,
    }

    #[event]
    struct ProfileExerciseDone has drop, store {
        profile_address: address,
        exercise_name: vector<u8>,
        workout_count: u64,
    }

    #[event]
    struct ExerciseAdded has drop, store {
        added_exercise_name: vector<u8>,
    }

    #[event]
    struct ExerciseRemoved has drop, store {
        removed_exercise_name: vector<u8>,
    }

    #[event]
    struct ProfileReset has drop, store {
        profile_address: address,
    }

    fun init_module(account: &signer) {
        let constructor_ref = object::create_object(signer::address_of(account));
        let profile = Profile {
          exercises_completed: vector::empty<ProfileExercise>(),
          total_workouts: 0,
          delete_ref: object::generate_delete_ref(&constructor_ref),
          last_random_exercise: 999
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

        let description = utf8(WORKOUT_COLLECTION_DESCRIPTION);
        let name = utf8(WORKOUT_COLLECTION_NAME);
        let uri = utf8(WORKOUT_COLLECTION_URI);

        collection::create_unlimited_collection(
            account,
            description,
            name,
            option::none(),
            uri,
        );

        // let account_address = signer::address_of(account);
        //event::emit(ProfileCreated { new_profile_address: account_address });
    }

    public entry fun start_exercise(account: &signer, resource_address: address, index: u64) acquires ExercisesList, Profile {
        let account_address = signer::address_of(account);
        let repository = borrow_global<ExercisesList>(resource_address);
        let exercise = *vector::borrow(&repository.exercises, index);
        let constructor_ref = object::create_object(account_address);

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
                    event::emit(ProfileExerciseDone {
                      profile_address: account_address,
                      exercise_name: exercise.name,
                      workout_count: existing_exercise.total_workouts
                    });
                    break
                };
                i = i + 1;
            };
            if (exercise_exists == false) {
                let new_exercise = ProfileExercise {
                    name: exercise.name,
                    total_workouts: 1,
                };
                event::emit(ProfileExerciseAdded { profile_address: account_address, exercise_name: exercise.name });
                vector::push_back(&mut profile.exercises_completed, new_exercise);
            }

        } else {
            let profile = Profile {
              exercises_completed: vector::empty<ProfileExercise>(),
              total_workouts: 1,
              delete_ref: object::generate_delete_ref(&constructor_ref),
              last_random_exercise: 999
            };

            event::emit(ProfileExerciseAdded { profile_address: account_address, exercise_name: exercise.name });

            let new_exercise = ProfileExercise {
                name: exercise.name,
                total_workouts: 1,
            };

            event::emit(ProfileExerciseAdded { profile_address: account_address, exercise_name: exercise.name });

            vector::push_back(&mut profile.exercises_completed, new_exercise);
            move_to(account, profile);
        };
    }

    public entry fun add_exercise(account: &signer, name: vector<u8>) acquires ExercisesList {
        let account_address = signer::address_of(account);
        let repository = borrow_global_mut<ExercisesList>(account_address);
        let exercise = Exercise { name };

        event::emit(ExerciseAdded { added_exercise_name: name });

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

                event::emit(ExerciseRemoved { removed_exercise_name: name });
                break
            };
            i = i + 1;
        };
    }

    public entry fun mint_nft(account: &signer, index: u64) acquires Profile {
        let account_address = signer::address_of(account);
        let profile = borrow_global<Profile>(account_address);
        let exercise = *vector::borrow(&profile.exercises_completed, index);

        assert!(exercise.total_workouts > 4, INCORRECT_COUNT);

        let description = utf8(b"At least 5 exercises completed");
        let uri = utf8(WORKOUT_COLLECTION_URI);
        let col_name = utf8(WORKOUT_COLLECTION_NAME);

        token::create_named_token(
            account,
            col_name,
            description,
            utf8(exercise.name),
            option::none(),
            uri,
        );
    }

    public entry fun reset_my_stats(account: &signer) acquires Profile {
        let account_address = signer::address_of(account);
        assert!(exists<Profile>(account_address), DOES_NOT_EXIST);
        let profile = borrow_global_mut<Profile>(account_address);

        profile.exercises_completed = vector::empty<ProfileExercise>();
        profile.total_workouts = 0;
        profile.last_random_exercise = 999;

        event::emit(ProfileReset { profile_address: account_address });
    }

    public entry fun delete_profile(account: &signer) acquires Profile {
        let account_address = signer::address_of(account);
        assert!(exists<Profile>(account_address), DOES_NOT_EXIST);
        let Profile {
            total_workouts: _,
            exercises_completed: _,
            last_random_exercise: _,
            delete_ref,
        } = move_from<Profile>(account_address);
        object::delete(delete_ref);
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

      // Get the length of the vector
      let length = vector::length(&profile.exercises_completed);

      // Check if the index is within bounds
      assert!(index < length, VECTOR_OPERATION_ERROR);

      // Now it is safe to access the vector
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

    #[randomness]
    entry fun get_seven_exercises(account: &signer) acquires ExercisesList {
      let account_address = signer::address_of(account);

      // Access the exercises list
      let repository = borrow_global<ExercisesList>(account_address);

      // Ensure the list has at least 7 exercises
      let len = vector::length(&repository.exercises);
      assert!(len >= 7, INCORRECT_LENGTH);

      // Create a local vector to store the exercise names
      let selected_exercises: vector<vector<u8>> = vector::empty<vector<u8>>();

      let i = 0;
      while (i < 7) {
          // Generate a random index for the current iteration
          let index = get_random_number(len - i);

          // Retrieve the random exercise's name and store it in the local vector
          let exercise = *vector::borrow(&repository.exercises, index);
          vector::push_back(&mut selected_exercises, exercise.name);

          i = i + 1;
      };

      // This is broken as it is, start_exercise is required not add_exercise
      let j = 0;
      while (j < 7) {
          let exercise_name = *vector::borrow(&selected_exercises, j);
          add_exercise(account, exercise_name);
          j = j + 1;
      }
    }

    #[view]
    public fun get_exercise(account: address, index: u64): Exercise acquires ExercisesList {
        let repository = borrow_global<ExercisesList>(account);
        let exercise = *vector::borrow(&repository.exercises, index);
        exercise
    }

    #[randomness]
    entry fun get_random_exercise(account: &signer) acquires ExercisesList, Profile {
        let repository = borrow_global<ExercisesList>(DEPLOYER);
        let len = vector::length(&repository.exercises);

        let index = get_random_number(len);

        start_exercise(account, DEPLOYER, index);

        let account_address = signer::address_of(account);
        assert!(exists<Profile>(account_address), DOES_NOT_EXIST);
        let profile = borrow_global_mut<Profile>(account_address);
        profile.last_random_exercise = index;
    }

    #[view]
    public fun get_last_random_number(account: address): u64 acquires Profile {
        assert!(exists<Profile>(account), DOES_NOT_EXIST);
        let profile = borrow_global<Profile>(account);
        profile.last_random_exercise
    }

    fun get_random_number(length: u64): u64 {
        aptos_framework::randomness::u64_range(0, length)
    }

    #[test(account = @0x1)]
    public fun test_init(account: signer) {
        init_module(&account);
        let account_address = signer::address_of(&account);
        assert!(exists<Profile>(account_address), DOES_NOT_EXIST);
        assert!(exists<ExercisesList>(account_address), DOES_NOT_EXIST);
    }

    #[test(account = @0x1), expected_failure]
    public fun test_without_init_failure(account: signer) {
        let account_address = signer::address_of(&account);
        assert!(exists<Profile>(account_address), DOES_NOT_EXIST);
        assert!(exists<ExercisesList>(account_address), DOES_NOT_EXIST);
    }

    #[test(account = @0x1)]
    public fun test_length(account: signer) acquires ExercisesList {
        init_module(&account);
        let account_address = signer::address_of(&account);
        let exercises = get_exercises_list_count(account_address);
        assert!(exercises == 7, INCORRECT_COUNT);

        let name = get_exercise_name_by_index(account_address, 2);
        let shoulders = b"Shoulders";
        assert!(name == shoulders, INCORRECT_ITEM);
    }

    #[test(account = @0x1)]
    public fun test_adding_an_exercise(account: signer) acquires ExercisesList {
        init_module(&account);
        let name = b"Test Exercise";
        add_exercise(&account, name);

        let account_address = signer::address_of(&account);
        let exercises = get_exercises_list_count(account_address);
        assert!(exercises == 8, INCORRECT_COUNT);

        let exercise = get_exercise(account_address, 7);
        assert!(exercise.name == name, INCORRECT_ITEM);
    }

    #[test(account = @0x1)]
    public fun test_removing_an_exercise(account: signer) acquires ExercisesList {
        init_module(&account);
        let name = b"Legs";
        remove_exercise(&account, name);

        let account_address = signer::address_of(&account);
        let exercises = get_exercises_list_count(account_address);
        assert!(exercises == 6, INCORRECT_COUNT);

        remove_exercise(&account, name);
        let exercises = get_exercises_list_count(account_address);
        assert!(exercises == 6, INCORRECT_COUNT);

        let exercise = get_exercise(account_address, 3);
        assert!(exercise.name == b"Arms", INCORRECT_ITEM);
    }

    #[test(account = @0x1, account_two = @0x2)]
    public fun test_start_exercise(account: signer, account_two: signer) acquires Profile, ExercisesList {
        init_module(&account);
        let owner_address = signer::address_of(&account);
        start_exercise(&account_two, owner_address, 1);
        let account_address = signer::address_of(&account_two);

        let profile = borrow_global<Profile>(account_address);
        let exercises = profile.exercises_completed;
        assert!(vector::length(&exercises) == 1, INCORRECT_LENGTH);

        let owner_address = signer::address_of(&account);
        start_exercise(&account_two, owner_address, 1);
        let profile = borrow_global<Profile>(account_address);
        let new_exercises = profile.exercises_completed;
        assert!(vector::length(&new_exercises) == 1, INCORRECT_LENGTH);

        let exercise = get_profile_exercise(account_address, 0);
        assert!(exercise.name == b"Back", INCORRECT_ITEM);
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
        assert!(vector::length(&top_exercises) == 3, INCORRECT_LENGTH);

        let top_exercise = *vector::borrow(&top_exercises, 0);
        assert!(top_exercise.name == b"Legs", INCORRECT_ITEM);
    }

    #[test(account = @0x1, account_two = @0x2), expected_failure]
    public fun test_mint_nft(account: signer, account_two: signer) acquires Profile, ExercisesList {
      init_module(&account);
      let owner_address = signer::address_of(&account);
      start_exercise(&account_two, owner_address, 0);
      start_exercise(&account_two, owner_address, 1);
      start_exercise(&account_two, owner_address, 0);
      start_exercise(&account_two, owner_address, 0);
      start_exercise(&account_two, owner_address, 0);
      start_exercise(&account_two, owner_address, 0);
      mint_nft(&account_two, 0);

      let token_name = utf8(b"Chest");
      let collection_name = utf8(WORKOUT_COLLECTION_NAME);

      let exercise_seed = token::create_token_seed(&collection_name, &token_name);

      let user_address = signer::address_of(&account_two);
      let token_address = object::create_object_address(&user_address, exercise_seed);
      let token = object::address_to_object<Token>(token_address);

      assert!(object::is_owner(token, user_address), INCORRECT_ITEM);
    }

    #[test(account = @0x1), expected_failure]
    public fun test_mint_nft_failure(account: signer) acquires Profile, ExercisesList {
      init_module(&account);
      let owner_address = signer::address_of(&account);

      start_exercise(&account, owner_address, 1);
      mint_nft(&account, 0);
    }

    #[test(account = @0x1)]
    public fun test_reset_my_tests(account: signer) acquires Profile, ExercisesList {
        init_module(&account);
        let account_address = signer::address_of(&account);
        start_exercise(&account, account_address, 0);

        let profile = borrow_global<Profile>(account_address);
        let exercises = profile.exercises_completed;
        assert!(vector::length(&exercises) == 1, INCORRECT_LENGTH);
        assert!(profile.total_workouts == 1, INCORRECT_COUNT);

        reset_my_stats(&account);
        let profile = borrow_global<Profile>(account_address);
        let exercises = profile.exercises_completed;
        assert!(vector::length(&exercises) == 0, INCORRECT_LENGTH);
        assert!(profile.total_workouts == 0, INCORRECT_COUNT);
    }

    #[test(account = @0x1)]
    public fun test_delete_profile(account: signer) acquires Profile, ExercisesList {
        init_module(&account);
        let account_address = signer::address_of(&account);
        start_exercise(&account, account_address, 0);

        let profile = borrow_global<Profile>(account_address);
        let exercises = profile.exercises_completed;
        assert!(vector::length(&exercises) == 1, INCORRECT_LENGTH);
        assert!(profile.total_workouts == 1, INCORRECT_COUNT);

        delete_profile(&account);
        assert!(!exists<Profile>(account_address), DOES_NOT_EXIST);
    }

    #[test(account = @0x1)]
    public fun test_getting_a_random_number(account: signer) acquires Profile, ExercisesList {
        init_module(&account);
        let account_address = signer::address_of(&account);
        start_exercise(&account, account_address, 0);
        let random_number = get_last_random_number(account_address);
        assert!(random_number == 999, INCORRECT_ITEM);
    }
}
